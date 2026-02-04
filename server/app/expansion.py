from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

import requests

from .config import settings
from .models import Dependency, Task


@dataclass
class ExpansionResult:
    tasks: List[Task]
    deps: List[Dependency]


class HeuristicExpander:
    def expand(self, task: Task) -> Optional[ExpansionResult]:
        title = task.title.lower()
        if "grocery" in title or "groceries" in title:
            return _simple_subtasks(
                task,
                [
                    ("Make a short list", 10),
                    ("Shop essentials", 45),
                    ("Put away items", 15),
                ],
            )
        if "laundry" in title:
            return _simple_subtasks(
                task,
                [
                    ("Sort clothes", 10),
                    ("Run wash", 60),
                    ("Fold and put away", 20),
                ],
            )
        if "email" in title or "inbox" in title:
            return _simple_subtasks(
                task,
                [
                    ("Scan for urgent", 5),
                    ("Reply to priority", 15),
                    ("Archive the rest", 10),
                ],
            )
        return None


def _simple_subtasks(task: Task, steps: List[Tuple[str, int]]) -> ExpansionResult:
    subtasks: List[Task] = []
    deps: List[Dependency] = []
    for idx, (title, estimate) in enumerate(steps):
        subtask_id = f"{task.id}-{idx}"
        subtasks.append(
            Task(
                id=subtask_id,
                title=title,
                created_at=task.created_at,
                deadline=task.deadline,
                estimate_minutes=estimate,
                energy=task.energy,
                tags=task.tags,
                parent_id=task.id,
                status=task.status,
                next_micro_step=title,
            )
        )
        if idx > 0:
            deps.append(Dependency(before_id=subtasks[idx - 1].id, after_id=subtasks[idx].id))
    return ExpansionResult(tasks=subtasks, deps=deps)


def expand_with_ollama(task: Task) -> Optional[ExpansionResult]:
    if not settings.ollama_enabled:
        return None
    prompt = _build_prompt(task)
    payload = {
        "model": settings.ollama_model,
        "prompt": prompt,
        "stream": False,
        "format": "json",
    }
    try:
        response = requests.post(
            f"{settings.ollama_base_url}/api/generate",
            json=payload,
            timeout=settings.ollama_timeout_s,
        )
        response.raise_for_status()
    except requests.RequestException:
        return None
    data = response.json()
    raw = data.get("response")
    if not raw:
        return None
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        return None
    if not isinstance(parsed, dict) or not parsed.get("should_expand"):
        return None
    subtasks = []
    deps = []
    for idx, subtask in enumerate(parsed.get("subtasks", [])):
        if not isinstance(subtask, dict) or "title" not in subtask:
            continue
        subtask_id = f"{task.id}-llm-{idx}"
        subtasks.append(
            Task(
                id=subtask_id,
                title=subtask["title"],
                created_at=task.created_at,
                deadline=task.deadline,
                estimate_minutes=subtask.get("estimate_minutes"),
                energy=task.energy,
                tags=task.tags,
                parent_id=task.id,
                status=task.status,
                next_micro_step=subtask.get("next_micro_step"),
            )
        )
    for dep in parsed.get("dependencies", []):
        if not isinstance(dep, dict):
            continue
        before_idx = dep.get("before_index")
        after_idx = dep.get("after_index")
        if isinstance(before_idx, int) and isinstance(after_idx, int):
            if 0 <= before_idx < len(subtasks) and 0 <= after_idx < len(subtasks):
                deps.append(
                    Dependency(
                        before_id=subtasks[before_idx].id,
                        after_id=subtasks[after_idx].id,
                    )
                )
    if not subtasks:
        return None
    return ExpansionResult(tasks=subtasks, deps=deps)


def expand_tasks(tasks: List[Task]) -> Tuple[List[Task], List[Dependency]]:
    heuristics = HeuristicExpander()
    expanded_tasks: List[Task] = []
    expanded_deps: List[Dependency] = []
    existing_children = {task.parent_id for task in tasks if task.parent_id}
    for task in tasks:
        if task.parent_id:
            continue
        if task.id in existing_children:
            continue
        result = heuristics.expand(task)
        if not result:
            result = expand_with_ollama(task)
        if result:
            expanded_tasks.extend(result.tasks)
            expanded_deps.extend(result.deps)
    return expanded_tasks, expanded_deps


def _build_prompt(task: Task) -> str:
    deadline = task.deadline.isoformat() if task.deadline else "none"
    estimate = task.estimate_minutes if task.estimate_minutes else "unknown"
    tags = ", ".join(task.tags) if task.tags else "none"
    return (
        "You are a task breakdown assistant. Output JSON only. "
        "Follow this schema:\n"
        "{\"should_expand\": true/false, \"reason\": \"short string\", "
        "\"subtasks\": [{\"title\": \"string\", "
        "\"estimate_minutes\": 10, \"next_micro_step\": \"string\"}], "
        "\"dependencies\": [{\"before_index\": 0, \"after_index\": 1}]}\n"
        "Task details:\n"
        f"title: {task.title}\n"
        f"deadline: {deadline}\n"
        f"estimate_minutes: {estimate}\n"
        f"tags: {tags}\n"
        "Granularity: medium. Provide 2-8 subtasks. Keep micro steps under 80 chars."
    )

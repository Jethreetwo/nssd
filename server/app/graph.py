from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Dict, Iterable, List, Optional, Set, Tuple

from .models import Dependency, Task


@dataclass
class CycleResult:
    cycle_edges: List[Dependency]
    suggest_break: List[Dependency]


def build_graph(deps: Iterable[Dependency]) -> Tuple[Dict[str, Set[str]], Dict[str, Set[str]]]:
    outgoing: Dict[str, Set[str]] = defaultdict(set)
    incoming: Dict[str, Set[str]] = defaultdict(set)
    for dep in deps:
        outgoing[dep.before_id].add(dep.after_id)
        incoming[dep.after_id].add(dep.before_id)
    return outgoing, incoming


def detect_cycle(tasks: Iterable[Task], deps: Iterable[Dependency]) -> Optional[CycleResult]:
    outgoing, incoming = build_graph(deps)
    nodes = {task.id for task in tasks}
    visiting: Set[str] = set()
    visited: Set[str] = set()
    stack: List[str] = []

    def dfs(node: str) -> Optional[List[str]]:
        visiting.add(node)
        stack.append(node)
        for nxt in outgoing.get(node, set()):
            if nxt not in nodes:
                continue
            if nxt in visiting:
                idx = stack.index(nxt)
                return stack[idx:] + [nxt]
            if nxt not in visited:
                found = dfs(nxt)
                if found:
                    return found
        visiting.remove(node)
        visited.add(node)
        stack.pop()
        return None

    for node in nodes:
        if node not in visited:
            cycle_nodes = dfs(node)
            if cycle_nodes:
                edges = []
                for i in range(len(cycle_nodes) - 1):
                    edges.append(Dependency(before_id=cycle_nodes[i], after_id=cycle_nodes[i + 1]))
                return CycleResult(cycle_edges=edges, suggest_break=[edges[0]])
    return None


def available_tasks(tasks: Iterable[Task], deps: Iterable[Dependency]) -> List[Task]:
    task_map = {task.id: task for task in tasks}
    outgoing, incoming = build_graph(deps)
    available = []
    for task in tasks:
        if task.status == "done":
            continue
        prereqs = incoming.get(task.id, set())
        if all(task_map[p].status == "done" for p in prereqs if p in task_map):
            available.append(task)
    return available


def topological_order(tasks: Iterable[Task], deps: Iterable[Dependency]) -> List[str]:
    outgoing, incoming = build_graph(deps)
    nodes = {task.id for task in tasks}
    indegree = {node: len(incoming.get(node, set())) for node in nodes}
    queue = deque([node for node, degree in indegree.items() if degree == 0])
    order: List[str] = []
    while queue:
        node = queue.popleft()
        order.append(node)
        for nxt in outgoing.get(node, set()):
            if nxt not in indegree:
                continue
            indegree[nxt] -= 1
            if indegree[nxt] == 0:
                queue.append(nxt)
    return order


def score_tasks(tasks: Iterable[Task], mode: str) -> Dict[str, float]:
    now = datetime.now(timezone.utc)
    scores: Dict[str, float] = {}
    for task in tasks:
        score = 0.0
        if task.deadline:
            delta = (task.deadline - now).total_seconds() / 3600
            if delta < 0:
                score += 100
            else:
                score += max(0, 50 - delta)
        if task.last_skipped_at:
            skipped_hours = (now - task.last_skipped_at).total_seconds() / 3600
            score -= max(0, 10 - min(skipped_hours, 10))
        score -= task.skip_count * 0.5
        if task.estimate_minutes:
            if mode == "quick":
                score += 10 if task.estimate_minutes <= 15 else -5
            elif mode == "deep":
                score += 10 if task.estimate_minutes >= 30 else -3
            else:
                score += 5 if task.estimate_minutes <= 30 else 0
        scores[task.id] = score
    return scores


def order_available(tasks: List[Task], deps: List[Dependency], mode: str) -> List[str]:
    available = available_tasks(tasks, deps)
    scores = score_tasks(available, mode)
    deps_filtered = [dep for dep in deps if dep.before_id in {t.id for t in available} and dep.after_id in {t.id for t in available}]
    outgoing, incoming = build_graph(deps_filtered)
    indegree = {task.id: len(incoming.get(task.id, set())) for task in available}
    ready = [task.id for task in available if indegree[task.id] == 0]
    order: List[str] = []
    while ready:
        ready.sort(key=lambda task_id: scores.get(task_id, 0), reverse=True)
        node = ready.pop(0)
        order.append(node)
        for nxt in outgoing.get(node, set()):
            if nxt not in indegree:
                continue
            indegree[nxt] -= 1
            if indegree[nxt] == 0:
                ready.append(nxt)
    return order


def reinsert_skipped(order: List[str], task_id: str, deps: List[Dependency], k: int = 4) -> List[str]:
    if task_id not in order:
        return order
    outgoing, _ = build_graph(deps)
    descendants = _descendants(task_id, outgoing)
    current_index = order.index(task_id)
    max_index = len(order) - 1
    limit_index = max_index
    for idx, node in enumerate(order):
        if node in descendants:
            limit_index = min(limit_index, idx - 1)
            break
    target_index = min(limit_index, current_index + k)
    if target_index < current_index:
        target_index = current_index
    new_order = [node for node in order if node != task_id]
    new_order.insert(target_index, task_id)
    return new_order


def _descendants(root: str, outgoing: Dict[str, Set[str]]) -> Set[str]:
    seen: Set[str] = set()
    stack = [root]
    while stack:
        node = stack.pop()
        for child in outgoing.get(node, set()):
            if child not in seen:
                seen.add(child)
                stack.append(child)
    return seen

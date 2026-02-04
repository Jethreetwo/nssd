from __future__ import annotations

from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, Header, HTTPException

from .config import settings
from .expansion import expand_tasks
from .graph import detect_cycle, order_available, score_tasks
from .models import CycleError, ExpandRequest, ExpandResponse, SyncRequest, SyncResponse, TimelineBucket
from .storage import fetch_deps, fetch_tasks, init_db, insert_events, replace_deps, upsert_tasks

router = APIRouter()


def _auth(authorization: str = Header(default="")) -> None:
    if settings.auth_token and authorization != f"Bearer {settings.auth_token}":
        raise HTTPException(status_code=401, detail="Unauthorized")


@router.post("/v1/sync", response_model=SyncResponse, dependencies=[Depends(_auth)])
def sync(payload: SyncRequest) -> SyncResponse:
    init_db(settings.db_path)
    upsert_tasks(settings.db_path, payload.tasks)
    replace_deps(settings.db_path, payload.deps)
    insert_events(settings.db_path, payload.events)

    tasks = fetch_tasks(settings.db_path)
    deps = fetch_deps(settings.db_path)

    expanded_tasks, expanded_deps = expand_tasks(tasks)
    if expanded_tasks:
        upsert_tasks(settings.db_path, expanded_tasks)
        deps.extend(expanded_deps)
        replace_deps(settings.db_path, deps)
        tasks = fetch_tasks(settings.db_path)

    cycle = detect_cycle(tasks, deps)
    cycle_error = None
    if cycle:
        cycle_error = CycleError(
            message="Dependency cycle detected",
            cycle_edges=cycle.cycle_edges,
            suggest_break=cycle.suggest_break,
        )

    available_order = order_available(tasks, deps, payload.mode)
    scores = score_tasks([task for task in tasks if task.id in available_order], payload.mode)
    timeline = _build_timeline(tasks)

    return SyncResponse(
        server_timestamp=datetime.now(timezone.utc),
        tasks=tasks,
        deps=deps,
        available_order=available_order,
        scores=scores,
        timeline=timeline,
        cycle_error=cycle_error,
    )


@router.post("/v1/expand", response_model=ExpandResponse, dependencies=[Depends(_auth)])
def expand(payload: ExpandRequest) -> ExpandResponse:
    expanded_tasks, expanded_deps = expand_tasks(payload.tasks)
    return ExpandResponse(tasks=payload.tasks + expanded_tasks, deps=payload.deps + expanded_deps)


@router.get("/v1/health")
def health() -> dict:
    return {"ok": True, "version": "0.1.0"}


def _build_timeline(tasks: List) -> List[TimelineBucket]:
    buckets = {}
    for task in tasks:
        if task.deadline:
            day = task.deadline.date().isoformat()
            buckets.setdefault(day, []).append(task.id)
    return [TimelineBucket(date=day, due_task_ids=task_ids) for day, task_ids in sorted(buckets.items())]

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class EnergyLevel(str, Enum):
    low = "low"
    med = "med"
    high = "high"


class TaskStatus(str, Enum):
    todo = "todo"
    done = "done"


class Task(BaseModel):
    id: str
    title: str
    created_at: datetime
    deadline: Optional[datetime] = None
    estimate_minutes: Optional[int] = None
    energy: Optional[EnergyLevel] = None
    tags: List[str] = Field(default_factory=list)
    parent_id: Optional[str] = None
    status: TaskStatus = TaskStatus.todo
    last_skipped_at: Optional[datetime] = None
    skip_count: int = 0
    next_micro_step: Optional[str] = None


class Dependency(BaseModel):
    before_id: str
    after_id: str
    type: str = "hard"


class HistoryEvent(BaseModel):
    id: str
    task_id: str
    event_type: str
    timestamp: datetime
    date_bucket: str


class SyncRequest(BaseModel):
    device_id: str
    mode: str = "focus"
    client_timestamp: datetime
    tasks: List[Task]
    deps: List[Dependency]
    events: List[HistoryEvent]
    client_state_hash: str


class CycleError(BaseModel):
    message: str
    cycle_edges: List[Dependency]
    suggest_break: List[Dependency]


class TimelineBucket(BaseModel):
    date: str
    due_task_ids: List[str]


class SyncResponse(BaseModel):
    server_timestamp: datetime
    tasks: List[Task]
    deps: List[Dependency]
    available_order: List[str]
    scores: Dict[str, float]
    timeline: List[TimelineBucket]
    cycle_error: Optional[CycleError] = None


class ExpandRequest(BaseModel):
    tasks: List[Task]
    deps: List[Dependency]


class ExpandResponse(BaseModel):
    tasks: List[Task]
    deps: List[Dependency]

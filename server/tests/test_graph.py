from datetime import datetime, timezone

from app.graph import detect_cycle, order_available
from app.models import Dependency, Task


def _task(task_id: str) -> Task:
    return Task(id=task_id, title=task_id, created_at=datetime.now(timezone.utc))


def test_cycle_detection():
    tasks = [_task("a"), _task("b"), _task("c")]
    deps = [
        Dependency(before_id="a", after_id="b"),
        Dependency(before_id="b", after_id="c"),
        Dependency(before_id="c", after_id="a"),
    ]
    cycle = detect_cycle(tasks, deps)
    assert cycle is not None
    assert cycle.cycle_edges


def test_available_order_respects_deps():
    tasks = [_task("a"), _task("b"), _task("c")]
    deps = [Dependency(before_id="a", after_id="b")]
    order = order_available(tasks, deps, "focus")
    assert order.index("a") < order.index("b")

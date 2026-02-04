from app.graph import reinsert_skipped
from app.models import Dependency


def test_reinsert_skipped_respects_descendants():
    order = ["a", "b", "c", "d"]
    deps = [Dependency(before_id="b", after_id="d")]
    new_order = reinsert_skipped(order, "b", deps, k=3)
    assert new_order.index("b") < new_order.index("d")

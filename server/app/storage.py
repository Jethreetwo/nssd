from __future__ import annotations

import sqlite3
from datetime import datetime
from typing import Iterable, List, Tuple

from .models import Dependency, HistoryEvent, Task


def _connect(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(db_path: str) -> None:
    conn = _connect(db_path)
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            deadline TEXT,
            estimate_minutes INTEGER,
            energy TEXT,
            tags TEXT,
            parent_id TEXT,
            status TEXT NOT NULL,
            last_skipped_at TEXT,
            skip_count INTEGER NOT NULL,
            next_micro_step TEXT
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS deps (
            before_id TEXT NOT NULL,
            after_id TEXT NOT NULL,
            type TEXT NOT NULL,
            PRIMARY KEY (before_id, after_id)
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS events (
            id TEXT PRIMARY KEY,
            task_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            date_bucket TEXT NOT NULL
        )
        """
    )
    conn.commit()
    conn.close()


def upsert_tasks(db_path: str, tasks: Iterable[Task]) -> None:
    conn = _connect(db_path)
    cur = conn.cursor()
    cur.executemany(
        """
        INSERT INTO tasks (
            id, title, created_at, deadline, estimate_minutes, energy, tags,
            parent_id, status, last_skipped_at, skip_count, next_micro_step
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            title=excluded.title,
            created_at=excluded.created_at,
            deadline=excluded.deadline,
            estimate_minutes=excluded.estimate_minutes,
            energy=excluded.energy,
            tags=excluded.tags,
            parent_id=excluded.parent_id,
            status=excluded.status,
            last_skipped_at=excluded.last_skipped_at,
            skip_count=excluded.skip_count,
            next_micro_step=excluded.next_micro_step
        """,
        [
            (
                task.id,
                task.title,
                task.created_at.isoformat(),
                task.deadline.isoformat() if task.deadline else None,
                task.estimate_minutes,
                task.energy,
                ",".join(task.tags),
                task.parent_id,
                task.status,
                task.last_skipped_at.isoformat() if task.last_skipped_at else None,
                task.skip_count,
                task.next_micro_step,
            )
            for task in tasks
        ],
    )
    conn.commit()
    conn.close()


def replace_deps(db_path: str, deps: Iterable[Dependency]) -> None:
    conn = _connect(db_path)
    cur = conn.cursor()
    cur.execute("DELETE FROM deps")
    cur.executemany(
        "INSERT INTO deps (before_id, after_id, type) VALUES (?, ?, ?)",
        [(dep.before_id, dep.after_id, dep.type) for dep in deps],
    )
    conn.commit()
    conn.close()


def insert_events(db_path: str, events: Iterable[HistoryEvent]) -> None:
    conn = _connect(db_path)
    cur = conn.cursor()
    cur.executemany(
        """
        INSERT OR IGNORE INTO events (id, task_id, event_type, timestamp, date_bucket)
        VALUES (?, ?, ?, ?, ?)
        """,
        [
            (
                event.id,
                event.task_id,
                event.event_type,
                event.timestamp.isoformat(),
                event.date_bucket,
            )
            for event in events
        ],
    )
    conn.commit()
    conn.close()


def fetch_tasks(db_path: str) -> List[Task]:
    conn = _connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT * FROM tasks")
    rows = cur.fetchall()
    conn.close()
    return [_row_to_task(row) for row in rows]


def fetch_deps(db_path: str) -> List[Dependency]:
    conn = _connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT * FROM deps")
    rows = cur.fetchall()
    conn.close()
    return [Dependency(**dict(row)) for row in rows]


def fetch_events(db_path: str) -> List[HistoryEvent]:
    conn = _connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT * FROM events")
    rows = cur.fetchall()
    conn.close()
    return [_row_to_event(row) for row in rows]


def _row_to_task(row: sqlite3.Row) -> Task:
    return Task(
        id=row["id"],
        title=row["title"],
        created_at=datetime.fromisoformat(row["created_at"]),
        deadline=datetime.fromisoformat(row["deadline"]) if row["deadline"] else None,
        estimate_minutes=row["estimate_minutes"],
        energy=row["energy"],
        tags=row["tags"].split(",") if row["tags"] else [],
        parent_id=row["parent_id"],
        status=row["status"],
        last_skipped_at=(
            datetime.fromisoformat(row["last_skipped_at"]) if row["last_skipped_at"] else None
        ),
        skip_count=row["skip_count"],
        next_micro_step=row["next_micro_step"],
    )


def _row_to_event(row: sqlite3.Row) -> HistoryEvent:
    return HistoryEvent(
        id=row["id"],
        task_id=row["task_id"],
        event_type=row["event_type"],
        timestamp=datetime.fromisoformat(row["timestamp"]),
        date_bucket=row["date_bucket"],
    )

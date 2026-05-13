-- todo-v1: a simple todo format with status, due date, and tags.

CREATE TABLE todo_v1_tasks (
    id           TEXT PRIMARY KEY,
    title        TEXT NOT NULL,
    body         TEXT,
    created_at   TEXT NOT NULL,
    updated_at   TEXT NOT NULL,
    status       TEXT,           -- e.g. 'open', 'done', 'archived'
    due_at       TEXT,           -- ISO 8601
    completed_at TEXT             -- ISO 8601
);

CREATE TABLE todo_v1_tags (
    note_id    TEXT NOT NULL REFERENCES todo_v1_tasks(id),
    label      TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

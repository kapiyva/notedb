-- todo: a simple todo format with status, due date, and tags.

CREATE TABLE todo_task (
    id           TEXT PRIMARY KEY,
    title        TEXT,
    body         TEXT NOT NULL,
    created_at   TEXT NOT NULL,
    updated_at   TEXT NOT NULL,
    status       TEXT,           -- e.g. 'open', 'done', 'archived'
    due_at       TEXT,           -- ISO 8601
    completed_at TEXT             -- ISO 8601
);

CREATE TABLE todo_tag (
    task_id TEXT NOT NULL REFERENCES todo_task(id),
    label   TEXT NOT NULL,
    PRIMARY KEY (task_id, label)
);

-- todo: a simple todo format with status, due date, and tags.
-- Safe to re-apply to an existing database (Convention 6).

CREATE TABLE IF NOT EXISTS todo_task (
    id           TEXT PRIMARY KEY,
    title        TEXT,
    body         TEXT NOT NULL,
    created_at   TEXT NOT NULL,
    updated_at   TEXT NOT NULL,
    status       TEXT,           -- e.g. 'open', 'done', 'archived'
    due_at       TEXT,           -- ISO 8601
    completed_at TEXT             -- ISO 8601
);

CREATE TABLE IF NOT EXISTS todo_tag (
    task_id TEXT NOT NULL REFERENCES todo_task(id),
    label   TEXT NOT NULL,
    PRIMARY KEY (task_id, label)
);

CREATE TABLE IF NOT EXISTS todo_meta (
    id             INTEGER PRIMARY KEY CHECK (id = 1),
    schema_version INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS todo_task_due_at_idx ON todo_task(due_at);

-- Views hold no state, so they are always rebuilt from the current definition.
DROP VIEW IF EXISTS todo_open_view;
CREATE VIEW todo_open_view AS
SELECT id, title, body, due_at, created_at, updated_at
FROM todo_task
WHERE status IS NULL OR status = 'open'
ORDER BY due_at;

-- Stamp the schema version this file defines (Convention 7).
INSERT INTO todo_meta (id, schema_version) VALUES (1, 1)
ON CONFLICT (id) DO UPDATE SET schema_version = excluded.schema_version;

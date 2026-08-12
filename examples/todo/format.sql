-- todo: a simple todo format with status, due date, and tags.
-- Safe to re-apply to an existing database (Convention 6).

-- Single-value property (Convention 4): each task references one status.
CREATE TABLE IF NOT EXISTS todo_status (
    id    TEXT PRIMARY KEY,
    label TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS todo_task (
    id           TEXT PRIMARY KEY,
    title        TEXT,
    body         TEXT NOT NULL,
    created_at   TEXT NOT NULL,
    updated_at   TEXT NOT NULL,
    status_id    TEXT REFERENCES todo_status(id),
    due_at       TEXT,           -- ISO 8601
    completed_at TEXT            -- ISO 8601
);

-- Multi-value property (Convention 4): tasks and tags, many-to-many.
CREATE TABLE IF NOT EXISTS todo_tag (
    id    TEXT PRIMARY KEY,     -- UUID recommended
    label TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS todo_task_tag (
    task_id TEXT NOT NULL REFERENCES todo_task(id),
    tag_id  TEXT NOT NULL REFERENCES todo_tag(id),
    PRIMARY KEY (task_id, tag_id)
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
WHERE status_id IS NULL OR status_id = 'open'
ORDER BY due_at;

-- Seed the format-defined status vocabulary. Fixed ids let the view filter on
-- them, and DO NOTHING keeps user-edited labels intact on re-application.
INSERT INTO todo_status (id, label) VALUES
    ('open', 'Open'),
    ('done', 'Done'),
    ('archived', 'Archived')
ON CONFLICT (id) DO NOTHING;

-- Stamp the schema version this file defines (Convention 7).
INSERT INTO todo_meta (id, schema_version) VALUES (1, 1)
ON CONFLICT (id) DO UPDATE SET schema_version = excluded.schema_version;

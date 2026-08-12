-- basic: a minimal note.db format with only the required columns.
-- Safe to re-apply to an existing database (Convention 6).

CREATE TABLE IF NOT EXISTS basic_note (
    id         TEXT PRIMARY KEY,
    title      TEXT,
    body       TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS basic_meta (
    id             INTEGER PRIMARY KEY CHECK (id = 1),
    schema_version INTEGER NOT NULL
);

-- Stamp the schema version this file defines (Convention 7).
INSERT INTO basic_meta (id, schema_version) VALUES (1, 1)
ON CONFLICT (id) DO UPDATE SET schema_version = excluded.schema_version;

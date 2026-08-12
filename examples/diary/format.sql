-- diary: a simple diary format with one entry per date and tags.
-- Safe to re-apply to an existing database (Convention 6).

CREATE TABLE IF NOT EXISTS diary_entry (
    id         TEXT PRIMARY KEY,
    title      TEXT,
    body       TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    entry_date TEXT,             -- ISO 8601 date (YYYY-MM-DD)
    mood       TEXT              -- free text or rating
);

CREATE TABLE IF NOT EXISTS diary_tag (
    entry_id TEXT NOT NULL REFERENCES diary_entry(id),
    label    TEXT NOT NULL,
    PRIMARY KEY (entry_id, label)
);

CREATE TABLE IF NOT EXISTS diary_meta (
    id             INTEGER PRIMARY KEY CHECK (id = 1),
    schema_version INTEGER NOT NULL
);

-- Stamp the schema version this file defines (Convention 7).
INSERT INTO diary_meta (id, schema_version) VALUES (1, 1)
ON CONFLICT (id) DO UPDATE SET schema_version = excluded.schema_version;

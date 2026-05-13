-- diary-v1: a simple diary format with one entry per date and tags.

CREATE TABLE diary_v1_entries (
    id         TEXT PRIMARY KEY,
    title      TEXT NOT NULL,
    body       TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    entry_date TEXT,             -- ISO 8601 date (YYYY-MM-DD)
    mood       TEXT              -- free text or rating
);

CREATE TABLE diary_v1_tags (
    note_id    TEXT NOT NULL REFERENCES diary_v1_entries(id),
    label      TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

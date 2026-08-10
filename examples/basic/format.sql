-- basic: a minimal note.db format with only the required columns.

CREATE TABLE basic_note (
    id         TEXT PRIMARY KEY,
    title      TEXT,
    body       TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

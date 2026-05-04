-- basic-v1: a minimal note.db format with only the required columns.

CREATE TABLE basic_v1_notes (
    id         TEXT PRIMARY KEY,
    title      TEXT NOT NULL,
    body       TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

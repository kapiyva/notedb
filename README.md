# note.db

Minimal SQLite conventions for personal knowledge formats.

English | [日本語](README.ja.md)

Licensed under the [GNU General Public License v3.0](LICENSE).

## What is note.db?

note.db is a set of shared conventions for using SQLite as a foundation for personal knowledge.

Tasks, notes, ideas, journals — the digital notebook that holds them has no portable, durable, open common standard. Each note tool stores its data in its own format, leaving a gap.

note.db defines a set of conventions to fill this gap. It specifies only the foundation — the minimum shape of a note table, naming rules — and leaves concrete expression to each format (a set of DDL representing a particular methodology, e.g. `zettelkasten-v1`, `evergreen-v1`). On this shared foundation, multiple formats can coexist in the same SQLite file, and tools work across formats.

note.db is not a library, CLI, or application — it is the conventions themselves. Anyone can publish a format or build tooling on top of it.

## Why SQLite?

The traces of your thinking deserve a longer life than any app. Whatever app is discontinued, whatever service shuts down, they should remain in your hands.

SQL is a mature open standard with decades of history. Pulling fragments together with views, noticing patterns through aggregation, returning to the past through search — the vocabulary for flipping through your records, recalling them, and reconnecting them is all there in the standard.

SQLite implements that SQL as a single file, readable and writable in any environment — the de facto standard.

The same motivation might seem satisfied by a pile of files like Markdown. But each file is an independent document, with no shared way to bind them together. How tags and relationships are expressed is left to loose conventions — frontmatter keys, folder structures — that depend on each file and the user's discipline, and there is no way to distribute that convention itself so that another tool can apply it consistently. note.db puts that role on the SQLite schema. A format is a DDL — a distributable artifact — that takes effect as structure the moment the database is opened, and aggregation and cross-cutting search come built in as SQL.

---

## Conventions

### 1. Note Table

The central concept of note.db is the note table. Any table that has at least the following columns is a note table.

```sql
id         TEXT PRIMARY KEY  -- UUID recommended
title      TEXT NOT NULL
body       TEXT              -- nullable
created_at TEXT NOT NULL     -- ISO 8601
updated_at TEXT NOT NULL     -- ISO 8601
```

A format must have at least one note table.

How note tables are used is up to the format designer. For Zettelkasten, for example, a single note table with links managed in a separate table is valid, as is a separate note table for each note type (literature note, permanent note, etc.).

### 2. Additional Tables

A format may include tables beyond note tables, such as tags, links, or settings. Because multiple formats can coexist in a single SQLite database, all table and view names must follow the prefix rule in Convention 3 to prevent name collisions.

### 3. Prefixes

Table names and view names must be prefixed with the format name. Because SQL identifiers do not allow hyphens, the prefix uses underscores even when the format name contains hyphens (e.g. the format `zettelkasten-v1` uses the prefix `zettelkasten_v1`).

```
<format>_<table>     -- e.g. zettelkasten_v1_notes, evergreen_v1_notes
<format>_v_<view>    -- e.g. zettelkasten_v1_v_graph (views are recommended, not required)
```

### 4. Property Tables

A property table represents a labeled one-to-many relationship attached to a note. Any table that satisfies all of the following is a property table:

```sql
note_id    TEXT NOT NULL REFERENCES <note_table>(id)
label      TEXT NOT NULL
created_at TEXT NOT NULL  -- ISO 8601
updated_at TEXT NOT NULL  -- ISO 8601
```

Other columns are at the format designer's discretion (and remain nullable per Convention 5). A property table may include additional foreign keys to other note tables under any other column name.

Tables that reference a note table but do not match this shape are not property tables; note.db places no restrictions on them.

### 5. Extensibility

- On note tables and property tables, columns beyond those specified by note.db must be nullable
- Changing column types or dropping columns is discouraged as it breaks compatibility with tools and other versions of a format reading the same database
- Anything not defined by note.db is left to the format designer

---

## What note.db Intentionally Leaves Out

These are excluded to keep note.db minimal and methodology-agnostic.

- Mandatory enforcement of integrity at the DB level
- How CRUD operations should be implemented
- Any obligation to provide views
- How a particular methodology must be expressed
- Hints about UI or presentation

---

## Publishing a Format

1. Prepare a DDL file (`format.sql`) that satisfies note.db.
2. Prepare a `spec.md` describing the design intent.
3. Publish both in any repository.

The format name `<name>-v<N>` is recommended (e.g. `zettelkasten-v1`).

## Examples

- [`basic-v1`](examples/basic-v1/format.sql) — a minimal format with only the required columns.
- [`todo-v1`](examples/todo-v1/format.sql) — a simple todo format with status, due date, and tags.
- [`diary-v1`](examples/diary-v1/format.sql) — a simple diary format with one entry per date and tags.

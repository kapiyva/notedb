# note.sql

Minimal SQLite conventions for personal knowledge formats.

English | [日本語](README.ja.md)

Licensed under the [GNU General Public License v3.0](LICENSE).

## What is note.sql?

note.sql is a set of shared conventions for using SQLite as a foundation for personal knowledge.

Tasks, notes, ideas, journals — the digital notebook that holds them has no portable, durable, open common standard. Each note tool stores its data in its own format, leaving a gap.

note.sql defines a set of conventions to fill this gap. It specifies only the foundation — the minimum shape of a note table, naming rules — and leaves concrete expression to each format (a set of DDL representing a particular methodology, e.g. `zettelkasten`, `evergreen`). On this shared foundation, multiple formats can coexist in the same SQLite file, and tools work across formats.

note.sql is not a library, CLI, or application — it is the conventions themselves. Anyone can publish a format or build tooling on top of it.

## Why SQLite?

The traces of your thinking deserve a longer life than any app. Whatever app is discontinued, whatever service shuts down, they should remain in your hands.

SQL is a mature open standard with decades of history. Pulling fragments together with views, noticing patterns through aggregation, returning to the past through search — the vocabulary for flipping through your records, recalling them, and reconnecting them is all there in the standard.

SQLite implements that SQL as a single file, readable and writable in any environment — the de facto standard.

The same motivation might seem satisfied by a pile of files like Markdown. But each file is an independent document, with no shared way to bind them together. How tags and relationships are expressed is left to loose conventions — frontmatter keys, folder structures — that depend on each file and the user's discipline, and there is no way to distribute that convention itself so that another tool can apply it consistently. note.sql puts that role on the SQLite schema. A format is a DDL — a distributable artifact — that takes effect as structure the moment the database is opened, and aggregation and cross-cutting search come built in as SQL.

---

## Conventions

### 1. Note Table

The central concept of note.sql is the note table. Any table that has at least the following columns is a note table.

```sql
id         TEXT PRIMARY KEY  -- UUID recommended
title      TEXT              -- nullable
body       TEXT NOT NULL
created_at TEXT NOT NULL     -- ISO 8601
updated_at TEXT NOT NULL     -- ISO 8601
```

A format must have at least one note table.

`body` is the note's content and is required. `title` is an optional heading: many notes — quick captures, journal entries, fleeting notes — are body only, and giving a note a heading is itself an act of curation that not every methodology has.

How note tables are used is up to the format designer. For Zettelkasten, for example, a single note table with links managed in a separate table is valid, as is a separate note table for each note type (literature note, permanent note, etc.).

### 2. Additional Tables

A format may include tables beyond note tables, such as tags, links, or settings. Because multiple formats can coexist in a single SQLite database, all table and view names must follow the prefix rule in Convention 3 to prevent name collisions.

### 3. Prefixes

Table names and view names must be prefixed with the format name. Because SQL identifiers do not allow hyphens, the prefix uses underscores even when the format name contains hyphens (e.g. the format `cornell-notes` uses the prefix `cornell_notes`).

The part after the prefix uses the singular form (e.g. `..._note`, `..._task`, `..._tag` — not `..._notes`). This keeps names consistent and lets reference column names be derived mechanically as `<table>_id` (see Convention 4).

```
<format>_<table>      -- e.g. zettelkasten_note, evergreen_note
<format>_<view>_view  -- e.g. zettelkasten_graph_view (views are recommended, not required)
```

### 4. Property Tables

A property table holds the vocabulary of values a note can carry — tags, statuses, moods. Any table that has at least the following columns is a property table.

```sql
id    TEXT PRIMARY KEY  -- UUID recommended
label TEXT NOT NULL     -- human-readable display value
```

`label` is the row's human-readable display value — the one string a generic client can always show for the row (the tag text, a status name).

A note references a property in one of two ways:

- **Single-value** — the note table holds a foreign key to the property table (e.g. `status_id TEXT REFERENCES todo_status(id)`). Each note carries at most one value. Per Convention 5, the column is nullable or has a `DEFAULT`.
- **Multi-value** — a junction table holds one foreign key to the note table and one to the property table (e.g. `todo_task_tag(task_id, tag_id)`). Each note carries any number of values.

In both patterns, a reference column is named after the table it points to: take the referenced table's singular name with the format prefix removed and append `_id`. So `todo_task` → `task_id`, `todo_tag` → `tag_id`, `diary_entry` → `entry_id`. This is what lets a generic client discover properties mechanically: find the tables shaped `id` + `label`, then follow the `<name>_id` columns that point at them — directly from a note table, or through a junction table.

note.sql implies no uniqueness beyond the primary key. Add constraints that match your semantics — e.g. `UNIQUE` on `label` where the vocabulary should not repeat, or a primary key of `(task_id, tag_id)` on a junction table where a note carries each tag at most once.

Tables that do not match this shape are not property tables; note.sql places no restrictions on them.

### 5. Extensibility

- On note tables, property tables, and the junction tables of Convention 4, columns beyond those specified by note.sql must be nullable or carry a `DEFAULT`, so that a client knowing only the note.sql-defined columns can still insert a valid row
- Changing column types or dropping columns is discouraged as it breaks compatibility with tools and other versions of a format reading the same database
- Anything not defined by note.sql is left to the format designer

### 6. Re-applicable format.sql

A `format.sql` is the complete, current definition of a format. It is recommended that it also be safe to re-apply to a database that already holds data — running it again converges the database on the current definition instead of failing or destroying anything.

- Tables and indexes use `CREATE ... IF NOT EXISTS`, so re-applying is a no-op for what already exists
- Views are dropped and recreated (`DROP VIEW IF EXISTS` then `CREATE VIEW`), so they always end up at the current definition

Views hold no state, so re-applying `format.sql` is itself the mechanism for updating them. This removes stale views from a format's concerns entirely, and leaves transforming existing tables as the only thing a migration has to do. How that transformation is carried out is outside note.sql.

### 7. Version Declaration

It is recommended that a format have a `<format>_meta` table: a single-row table holding at least `schema_version INTEGER NOT NULL`, which declares the format's current version.

```sql
id             INTEGER PRIMARY KEY CHECK (id = 1)  -- one row only
schema_version INTEGER NOT NULL
```

Further metadata is held as additional columns (nullable or with a `DEFAULT`, per Convention 5). The single row can be enforced with a constraint such as the `CHECK (id = 1)` above.

Because note.sql assumes multiple formats coexist in one database, a database-global marker such as `PRAGMA user_version` cannot serve this purpose: the version has to be held per format, which means a prefixed table (Conventions 2 and 3). A generic client can then detect the version of any format with a single query.

Advance `schema_version` for compatible evolution within the bounds of Convention 5. Breaking changes are published under a distinct name.

---

## What note.sql Intentionally Leaves Out

These are excluded to keep note.sql minimal and methodology-agnostic.

- Mandatory enforcement of integrity at the DB level
- How CRUD operations should be implemented
- Migration between versions of a format (only how a version is declared is defined — Convention 7)
- Any obligation to provide views
- How a particular methodology must be expressed
- Hints about UI or presentation

---

## Publishing a Format

1. Prepare a DDL file (`format.sql`) that satisfies note.sql.
2. Prepare a `spec.md` describing the design intent.
3. Publish both in any repository.

The format name becomes the table prefix (Convention 3), so choose a name distinctive enough to avoid colliding with other formats in the same database. The same applies when a breaking change is published under a distinct name (Convention 7). note.sql prescribes no versioning scheme beyond that.

## Examples

- [`basic`](examples/basic/format.sql) — a minimal format with only the required columns.
- [`todo`](examples/todo/format.sql) — a simple todo format with status, due date, and tags.
- [`diary`](examples/diary/format.sql) — a simple diary format with one entry per date and tags.

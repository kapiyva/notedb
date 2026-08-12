# note.db

Minimal SQLite conventions for personal knowledge formats.

English | [日本語](README.ja.md)

Licensed under the [GNU General Public License v3.0](LICENSE).

## What is note.db?

note.db is a set of shared conventions for using SQLite as a foundation for personal knowledge.

Tasks, notes, ideas, journals — the digital notebook that holds them has no portable, durable, open common standard. Each note tool stores its data in its own format, leaving a gap.

note.db defines a set of conventions to fill this gap. It specifies only the foundation — the minimum shape of a note table, naming rules — and leaves concrete expression to each format (a set of DDL representing a particular methodology, e.g. `zettelkasten`, `evergreen`). On this shared foundation, multiple formats can coexist in the same SQLite file, and tools work across formats.

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

The part after the prefix uses the singular form (e.g. `..._note`, `..._task`, `..._tag` — not `..._notes`). This keeps names consistent and lets a property table derive its reference column name mechanically as `<table>_id` (see Convention 4).

```
<format>_<table>      -- e.g. zettelkasten_note, evergreen_note
<format>_<view>_view  -- e.g. zettelkasten_graph_view (views are recommended, not required)
```

### 4. Property Tables

A property table represents a labeled one-to-many relationship attached to a note. Any table that satisfies all of the following is a property table (shown for a property table on the note table `zettelkasten_fleeting`, whose format is `zettelkasten` and whose bare table name is `fleeting`):

```sql
fleeting_id  TEXT NOT NULL REFERENCES zettelkasten_fleeting(id)
label        TEXT NOT NULL
```

The reference column is named after the note table it points to: take the referenced note table's singular name with the format prefix removed, and append `_id`. So a property table on `zettelkasten_fleeting` uses `fleeting_id REFERENCES zettelkasten_fleeting(id)`; likewise `todo_task` → `task_id` and `diary_entry` → `entry_id`.

`label` is the property's human-readable display value — the one string a generic client can always show for the row (the tag text, a file name, a link title). A one-to-many relationship with no such display value is not a property table; model it as a plain additional table (Convention 2).

note.db implies no uniqueness on a property table. Add a primary key or unique constraint that matches your semantics — e.g. `(task_id, label)` for tags, where a note carries each tag at most once, but not for attachments, where the same file name may legitimately repeat.

Other columns are at the format designer's discretion (nullable, or with a `DEFAULT`, per Convention 5). A property table may include additional foreign keys to other note tables under any other column name.

Tables that reference a note table but do not match this shape are not property tables; note.db places no restrictions on them.

### 5. Extensibility

- On note tables and property tables, columns beyond those specified by note.db must be nullable or carry a `DEFAULT`, so that a client knowing only the note.db-defined columns can still insert a valid row
- Changing column types or dropping columns is discouraged as it breaks compatibility with tools and other versions of a format reading the same database
- Anything not defined by note.db is left to the format designer

### 6. Re-applicable format.sql

A `format.sql` is the complete, current definition of a format. It is recommended that it also be safe to re-apply to a database that already holds data — running it again converges the database on the current definition instead of failing or destroying anything.

- Tables and indexes use `CREATE ... IF NOT EXISTS`, so re-applying is a no-op for what already exists
- Views are dropped and recreated (`DROP VIEW IF EXISTS` then `CREATE VIEW`), so they always end up at the current definition

Views hold no state, so re-applying `format.sql` is itself the mechanism for updating them. This removes stale views from a format's concerns entirely, and leaves transforming existing tables as the only thing a migration has to do. How that transformation is carried out is outside note.db.

### 7. Version Declaration

It is recommended that a format have a `<format>_meta` table: a single-row table holding at least `schema_version INTEGER NOT NULL`, which declares the format's current version.

```sql
id             INTEGER PRIMARY KEY CHECK (id = 1)  -- one row only
schema_version INTEGER NOT NULL
```

Further metadata is held as additional columns (nullable or with a `DEFAULT`, per Convention 5). The single row can be enforced with a constraint such as the `CHECK (id = 1)` above.

Because note.db assumes multiple formats coexist in one database, a database-global marker such as `PRAGMA user_version` cannot serve this purpose: the version has to be held per format, which means a prefixed table (Conventions 2 and 3). A generic client can then detect the version of any format with a single query.

Advance `schema_version` for compatible evolution within the bounds of Convention 5. Breaking changes are published under a distinct name.

---

## What note.db Intentionally Leaves Out

These are excluded to keep note.db minimal and methodology-agnostic.

- Mandatory enforcement of integrity at the DB level
- How CRUD operations should be implemented
- Migration between versions of a format (only how a version is declared is defined — Convention 7)
- Any obligation to provide views
- How a particular methodology must be expressed
- Hints about UI or presentation

---

## Publishing a Format

1. Prepare a DDL file (`format.sql`) that satisfies note.db.
2. Prepare a `spec.md` describing the design intent.
3. Publish both in any repository.

The format name becomes the table prefix (Convention 3), so choose a name distinctive enough to avoid colliding with other formats in the same database. The same applies when a breaking change is published under a distinct name (Convention 7). note.db prescribes no versioning scheme beyond that.

## Examples

- [`basic`](examples/basic/format.sql) — a minimal format with only the required columns.
- [`todo`](examples/todo/format.sql) — a simple todo format with status, due date, and tags.
- [`diary`](examples/diary/format.sql) — a simple diary format with one entry per date and tags.

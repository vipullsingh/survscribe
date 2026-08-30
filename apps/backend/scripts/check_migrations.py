#!/usr/bin/env python3
"""Static sanity check over the SurvScribe migration set.

This is NOT a PostgreSQL parser and it does NOT prove the SQL executes. Only applying
the migrations to a real Postgres does that (see migrations/README.md). What this does
catch is the class of defect a hand-assembled migration set actually hits:

  * unbalanced parentheses or dollar-quotes
  * a statement with no terminating semicolon
  * a forward reference -- a table, type or function used in migration N that is not
    created until migration N+1, which fails only when someone runs from scratch
  * an up-migration with no matching down-migration, or a table/type that no
    down-migration drops

Usage:  python apps/backend/scripts/check_migrations.py [migrations_dir]
Exit code 1 if any error is found, so it can be wired straight into CI.
"""
import io
import os
import re
import sys

MIGDIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "migrations")


def strip_comments(sql):
    """Remove -- comments, leaving string literals and $$ bodies intact."""
    out, i, n = [], 0, len(sql)
    while i < n:
        c = sql[i]
        if c == "'":
            j = i + 1
            while j < n:
                if sql[j] == "'":
                    if j + 1 < n and sql[j + 1] == "'":
                        j += 2
                        continue
                    break
                j += 1
            out.append(sql[i:j + 1])
            i = j + 1
        elif sql.startswith("$$", i):
            j = sql.find("$$", i + 2)
            j = n if j == -1 else j + 2
            out.append(sql[i:j])
            i = j
        elif sql.startswith("--", i):
            j = sql.find("\n", i)
            i = n if j == -1 else j + 1
            out.append("\n")
        else:
            out.append(c)
            i += 1
    return "".join(out)


def split_statements(sql):
    """Split on top-level semicolons. Returns (statements, unterminated_tail, depth)."""
    stmts, depth, buf, i, n = [], 0, [], 0, len(sql)
    while i < n:
        c = sql[i]
        if c == "'":
            j = i + 1
            while j < n:
                if sql[j] == "'":
                    if j + 1 < n and sql[j + 1] == "'":
                        j += 2
                        continue
                    break
                j += 1
            buf.append(sql[i:j + 1])
            i = j + 1
            continue
        if sql.startswith("$$", i):
            j = sql.find("$$", i + 2)
            j = n if j == -1 else j + 2
            buf.append(sql[i:j])
            i = j
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        elif c == ";" and depth == 0:
            stmts.append("".join(buf).strip())
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    return stmts, "".join(buf).strip(), depth


BUILTIN_TYPES = {
    "uuid", "text", "boolean", "bool", "date", "time", "inet", "jsonb", "json",
    "bigserial", "serial", "smallserial", "smallint", "integer", "int", "bigint",
    "numeric", "decimal", "real", "double", "citext", "timestamptz", "timestamp",
    "char", "varchar", "character", "bytea", "interval",
}

# Words that follow ON/ALTER TABLE in a non-table position.
NON_TABLE_TOKENS = {"each", "conflict", "delete", "update", "public", "row", "insert"}


def main():
    errors, warnings = [], []
    known_tables, known_types, known_funcs = set(), set(), set()

    files = sorted(f for f in os.listdir(MIGDIR) if f.endswith(".up.sql"))
    print("Checking %d up-migrations in %s\n" % (len(files), os.path.normpath(MIGDIR)))

    total_stmts = 0
    for fn in files:
        raw = io.open(os.path.join(MIGDIR, fn), encoding="utf-8").read()
        stmts, tail, depth = split_statements(strip_comments(raw))
        total_stmts += len(stmts)

        if depth != 0:
            errors.append("%s: unbalanced parentheses (final depth %d)" % (fn, depth))
        if tail:
            errors.append("%s: trailing text with no terminating ';' -> %r" % (fn, tail[:80]))
        if raw.count("$$") % 2:
            errors.append("%s: odd number of $$ dollar-quote delimiters" % fn)

        created_t, created_ty = set(), set()
        for s in stmts:
            m = re.match(r"(?is)\s*CREATE\s+TABLE\s+(?:IF NOT EXISTS\s+)?(\w+)", s)
            if m:
                created_t.add(m.group(1).lower())
            m = re.match(r"(?is)\s*CREATE\s+TYPE\s+(\w+)", s)
            if m:
                created_ty.add(m.group(1).lower())
            m = re.match(r"(?is)\s*CREATE\s+(?:OR REPLACE\s+)?FUNCTION\s+(\w+)", s)
            if m:
                known_funcs.add(m.group(1).lower())

        visible_t = known_tables | created_t
        visible_ty = known_types | created_ty

        for s in stmts:
            for tgt in re.findall(r"(?is)\bREFERENCES\s+(\w+)\s*\(", s):
                if tgt.lower() not in visible_t:
                    errors.append("%s: REFERENCES %s -- table not created in this or an "
                                  "earlier migration" % (fn, tgt))

            is_targeted = (re.match(r"(?is)\s*CREATE\s+(UNIQUE\s+)?INDEX", s)
                           or re.match(r"(?is)\s*(ALTER|CREATE TRIGGER|REVOKE|GRANT)", s))
            if is_targeted:
                for kw, tgt in re.findall(r"(?is)\b(ALTER TABLE|ON)\s+(\w+)\b", s):
                    t = tgt.lower()
                    if t in NON_TABLE_TOKENS:
                        continue
                    if t not in visible_t:
                        errors.append("%s: %s %s -- table not created in this or an "
                                      "earlier migration" % (fn, kw, tgt))

            for name in re.findall(r"(?is)\bEXECUTE\s+FUNCTION\s+(\w+)\s*\(", s):
                if name.lower() not in known_funcs:
                    errors.append("%s: trigger calls %s() -- function not created earlier"
                                  % (fn, name))

            if re.match(r"(?is)\s*CREATE\s+TABLE", s):
                body = s[s.index("(") + 1:s.rindex(")")]
                depth_in_body = 0
                for line in body.split("\n"):
                    at_top = depth_in_body == 0
                    depth_in_body += line.count("(") - line.count(")")
                    line = line.strip().rstrip(",")
                    if not at_top or not line:
                        continue
                    if line.upper().startswith(("CONSTRAINT", "PRIMARY KEY", "UNIQUE",
                                                "CHECK", "FOREIGN KEY", "EXCLUDE")):
                        continue
                    parts = line.split()
                    if len(parts) < 2:
                        continue
                    ty = re.sub(r"\(.*", "", parts[1]).lower()
                    if ty in BUILTIN_TYPES or ty in visible_ty or ty.endswith("[]"):
                        continue
                    warnings.append("%s: column '%s' has unrecognised type '%s'"
                                    % (fn, parts[0], parts[1]))

        known_tables |= created_t
        known_types |= created_ty
        print("  %-52s %3d stmts  +%d tables +%d types"
              % (fn, len(stmts), len(created_t), len(created_ty)))

    ups = set(f[:-7] for f in files)
    downs = set(f[:-9] for f in os.listdir(MIGDIR) if f.endswith(".down.sql"))
    for missing in sorted(ups - downs):
        errors.append("%s.up.sql has no matching .down.sql" % missing)
    for orphan in sorted(downs - ups):
        errors.append("%s.down.sql has no matching .up.sql" % orphan)

    down_sql = "\n".join(
        io.open(os.path.join(MIGDIR, f), encoding="utf-8").read()
        for f in os.listdir(MIGDIR) if f.endswith(".down.sql")).lower()
    for t in sorted(known_tables):
        if not re.search(r"drop table if exists\s+%s\b" % re.escape(t), down_sql):
            warnings.append("table '%s' is created but never dropped by a down-migration" % t)
    for ty in sorted(known_types):
        if not re.search(r"drop type if exists\s+%s\b" % re.escape(ty), down_sql):
            warnings.append("type '%s' is created but never dropped by a down-migration" % ty)

    print("\nTotals: %d statements, %d tables, %d enum types, %d functions"
          % (total_stmts, len(known_tables), len(known_types), len(known_funcs)))
    print("\nERRORS   (%d):" % len(errors))
    for e in errors:
        print("  x", e)
    print("\nWARNINGS (%d):" % len(warnings))
    for w in warnings:
        print("  !", w)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

# Implementation Notes – Hospital Records Management System

## 1. Design decisions

**Logic lives in the database.** All business rules (who can be booked, how bills are computed,
state changes of an appointment) are in stored procedures and functions. Tables only enforce
structural integrity (PK/FK/CHECK/UNIQUE). One rule is enforced by *both* layers on purpose:
`book_appointment` checks the slot with `is_doctor_available` to give a friendly message, and a
function-based unique index `uq_doctor_slot` guarantees no double-booking even if two sessions
book at the same instant (the loser gets `DUP_VAL_ON_INDEX`, translated to `-20206`).

**Functions vs procedures.** Functions answer a question and have no side effects
(`calculate_age`, `get_patient_balance`, `calculate_bill_amount`, …) so they can be used in SQL.
`is_doctor_available` returns `'Y'/'N'` instead of `BOOLEAN` precisely so SQL can call it.
Procedures change data (`register_patient`, `add_medical_record`, …) or report results.

**Transaction control.** Procedures never `COMMIT` or `ROLLBACK` the caller's work. That lets
`add_medical_record` insert the record, complete the appointment and create the bill as one
atomic unit. The only exception is `log_error`, an `AUTONOMOUS_TRANSACTION`, so error rows
survive a rollback. `benchmark_bulk_vs_row` uses `ROLLBACK TO SAVEPOINT` so it cannot undo
unrelated work of the caller.

## 2. How each concept is used

| Concept | Practical use in this project |
|---|---|
| User-defined record | Group related input/rows: new patient, visit details, bill line |
| `%ROWTYPE` | Whole-row fetch (`SELECT *`), cursor rows, function return type |
| Associative array | Doctor name → workload, naturally sorted by key |
| Nested table | Dynamic result sets for `BULK COLLECT`; also a schema type usable in `TABLE()` |
| VARRAY | Small fixed list of legal statuses |
| Implicit cursor | Check the effect of the last DML: `SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND` |
| Explicit cursor | Row-by-row processing with a parameter and full lifecycle control |
| `BULK COLLECT` | Load all rows in one trip to the SQL engine |
| `FORALL` | Send all DML changes to the SQL engine in one trip |

## 3. Exception-handling strategy

1. **Expected business errors** become named application errors with `RAISE_APPLICATION_ERROR`
   (range -20001…-20999) and a message that tells the user what to fix.
2. **Predefined exceptions** are translated close to where they occur
   (`NO_DATA_FOUND` → "patient does not exist", `TOO_MANY_ROWS` → "ambiguous name",
   `DUP_VAL_ON_INDEX` → "phone already registered").
3. **Unexpected errors are never swallowed.** Every procedure ends with
   `WHEN OTHERS THEN … log_error(…); RAISE;` – logged for diagnosis and re-raised to the caller.
   Application errors (-20xxx) are re-raised without logging, to keep the log meaningful.
   Functions deliberately have no `WHEN OTHERS`, so an unknown error simply propagates;
   they never return a "default" value such as `0` or `NULL` that could be mistaken for a real result
   (e.g. `get_patient_balance` for an unknown patient raises an error instead of returning `0`).
4. **Bulk errors:** `FORALL … SAVE EXCEPTIONS` lets valid rows succeed; the `ORA-24381` handler reads
   `SQL%BULK_EXCEPTIONS`, reports each failed element and logs it. The affected counts are returned
   via `OUT` parameters, so callers know exactly what happened.
5. **Cursors are always closed**, including on the error path (`IF c%ISOPEN THEN CLOSE c`).

## 4. Performance considerations – bulk processing

**The cost model.** PL/SQL and SQL run in two different engines. Every SQL statement executed
inside a PL/SQL loop forces a *context switch* between them. A loop that inserts 100,000 rows
one by one makes 100,000 switches; the work inside the SQL engine is the same, but the switching
overhead dominates.

| Technique | Without bulk | With bulk |
|---|---|---|
| Reading *n* rows | *n* fetches (`FETCH … INTO` in a loop) | 1 fetch (`BULK COLLECT`), or *n / LIMIT* fetches |
| Writing *n* rows | *n* statements in a `FOR` loop | 1 statement (`FORALL`) |
| Context switches | ≈ *n* | ≈ 1 per batch |

**Where it is used here**

* `bulk_generate_bills` – one query loads every un-billed completed visit, one `FORALL` inserts all
  bills, so there is no context switch per bill.
* `bulk_update_doctor_fees` – `BULK COLLECT … LIMIT 100` + `FORALL UPDATE`. `LIMIT` keeps PGA memory
  bounded: a plain `BULK COLLECT` of millions of rows could exhaust session memory, so large sets
  are processed in batches.
* `benchmark_bulk_vs_row` – measures both techniques on the same data so the group can show real numbers
  during the demonstration (run `S10` in `test_success_cases.sql` and paste your own result into the
  table below; results depend on your database and machine).

| Rows | Row-by-row (ms) | FORALL (ms) | Speed-up |
|---|---|---|---|
| 100,000 | _fill in from your run_ | _fill in_ | _fill in_ |

**Trade-offs and limits (be ready to explain)**

* Bulk processing helps most with **many rows**; for 5–10 rows the difference is negligible, so the
  sample data volume alone does not show it – hence the benchmark with synthetic rows.
* It uses **more memory** (the whole batch sits in a collection) → use `LIMIT` for large sets.
* A single `UPDATE … SET … WHERE …` or `INSERT … SELECT` in plain SQL is faster still when no
  per-row PL/SQL logic is needed. `FORALL` is for cases where the data must first be processed
  in PL/SQL (here: fees are rounded/validated in PL/SQL, bills use a function).
* `FORALL` allows **one** DML statement; without `SAVE EXCEPTIONS`, the first error stops the
  statement and rolls back that statement's changes. With it, remaining rows continue and all
  errors are reported at the end.
* Calling `calculate_bill_amount` inside the `BULK COLLECT` query executes SQL per row inside that
  function; acceptable here for clarity and reuse. For very large volumes, the discount rule could
  be inlined in the query itself.

## 5. Known limitations / possible extensions

* Appointment times are matched exactly (no duration/overlap model).
* Payment recording, prescriptions and user roles are out of scope.
* Procedures print with `DBMS_OUTPUT`; a production system would return `SYS_REFCURSOR`s to an application.
* The code was written for Oracle 12c+ (referencing record fields inside `FORALL` needs 11g+).

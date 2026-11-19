# Airport Management Database — Part 1

Complete deliverable for the *Security of Databases* project
(University of Luxembourg, Master in Cybersecurity, 2026–2027).

Two things live here:

1. a **15-minute English presentation for 4 speakers** (PowerPoint + PDF + script);
2. a **working SQL Server 2019 implementation** of the airport database, including
   the 19-entity schema, sample data, least-privilege roles, row-level security,
   dynamic data masking, TDE, auditing and backups, with an automated test script.

---

## 1. Presentation (15 min, 4 speakers)

| File | Use |
|---|---|
| `slides/Airport_Database_Part1_EN.pptx` | Editable, 17 slides, 16:9, speaker notes embedded |
| `slides/Airport_Database_Part1_EN.pdf` | Flat version for review or a backup laptop |
| `slides/Speaker_Notes_EN.md` | Full script with timing, per speaker, readable on a phone |

| Part | Speaker | Time | Slides |
|---|---|---|---|
| Context & scope | 1 | 0:00 – 3:40 | 1–5 |
| The conceptual model | 2 | 3:40 – 8:35 | 6–9 |
| Who can do what | 3 | 8:35 – 11:40 | 10–12 |
| Technology & next steps | 4 | 11:40 – 15:00 | 13–17 |

Replace `[Speaker 4]` on the title slide (and in the notes) with the fourth presenter's name.
The notes are attached to each slide in PowerPoint (*View → Notes Page* or presenter view).

---

## 2. Database implementation

### Files

| File | Content |
|---|---|
| `sql/00_database.sql` | Creates `AirportDB`, the five schemas, full recovery model |
| `sql/01_schema.sql` | The 19 entities, keys, CHECK constraints, filtered unique indexes |
| `sql/02_seed.sql` | 15 people, 12 flights, 15 tickets, 8 employees, bans, licences |
| `sql/03_views_procedures.sql` | Filtered views (`vw_MyTickets`, `vw_AgentPassengerList`, …) and 7 stored procedures |
| `sql/04_security.sql` | Logins, 6 roles, GRANT/DENY, column-level rights, RLS policy, masking |
| `sql/05_tde_audit_backup.sql` | TDE + certificate backup, server/database audit, full/diff/log backups |
| `sql/06_tests.sql` | 22 automated PASS/FAIL checks, role by role |
| `sql/07_demo_queries.sql` | Read-only queries for the defence (load factor, bans, expired licences, audit trail) |
| `run_all.sh` | Rebuilds everything in order inside the container |
| `docs/test_results.txt` | Output of the last full run: **22/22 PASS** |

### Result of the last clean run

- 22 checks, 22 PASS, 0 FAIL.
- TDE state = **3 (Encrypted)**.
- Server audit `AirportAudit` and database specification `AirportDbAudit` enabled.
- Full, differential and log backups written and the full backup verified on disk.
- Audit trail proves it records both allowed reads and **denied** actions
  (`demo_hr` reading passports, `demo_security` deleting a ban).

### What each actor can actually do

| Login | Role | Person | Can | Cannot |
|---|---|---|---|---|
| `demo_passenger` | `role_passenger` | Anna Weber (P1) | See own profile, 3 own tickets, own flights; update own contact | See any other passenger, any price of others |
| `demo_checkin` | `role_checkin_agent` | Claire Muller (E1) | See the 8 tickets of flights 1–3, change seats there, check in, add luggage, see banned yes/no | See unassigned flights, ban reasons, passport data |
| `demo_coordinator` | `role_flight_coordinator` | Thomas Becker (E4) | Plan flights, assign gates and crew, read load factors | Read individual tickets or passenger identity (DENY) |
| `demo_security` | `role_security_officer` | Jan Kowalski (E2) | Read passports unmasked, read/create/update bans, read manifests | Delete a ban entry |
| `demo_hr` | `role_hr_manager` | Fatima Zahra (E3) | Full workforce CRUD, salaries, staff contact data | Read passports (DENY) |
| `demo_dba` | `role_dba` | — | DDL, backups, audit review, definitions | Read personal, commercial, salary or ban data (DENY) |
| `demo_reader` | — | — | Read passports **masked** (test account) | Unmask |

All demo logins use the password `Airport#2026!Demo` — local container only.

### How the row rules are enforced

| Rule from the report | Implementation |
|---|---|
| Passenger sees only their own tickets | `RLS` filter predicate on `Commercial.Ticket` + `vw_MyTickets` |
| Agent sees only passengers of assigned flights | `RLS` filter + `Security.AgentFlightAssignment` + `vw_AgentPassengerList` |
| Agent sees banned yes/no, never the reason | `Security.vw_PassengerBanStatus` exposes only the flag; `DENY` on `BanList` |
| Coordinator sees only aggregate figures | `vw_FlightLoad` (ownership chaining) + `DENY SELECT` on `Commercial.Ticket` |
| DBA cannot read business data | `DENY SELECT` on the sensitive tables; only DDL + backup rights |
| Ban is attributable | `BanList.AddedByEmployeeID` is mandatory and filled by `usp_AddBanEntry` |

### Run it

```bash
cd /home/jeremy/Projets/airport-database

docker run -d --name airport-sql -p 14333:1433 \
  -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='Airport#2026!Demo' \
  -e MSSQL_PID=Developer mcr.microsoft.com/mssql/server:2019-latest

./run_all.sh
```

Open a session:

```bash
docker exec -it airport-sql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'Airport#2026!Demo' -C
```

Useful inside `sqlcmd`:

```sql
USE AirportDB;
EXECUTE AS USER = 'demo_checkin';
SELECT * FROM Operational.vw_AgentPassengerList;
REVERT;
```

Reset from scratch:

```sql
ALTER DATABASE AirportDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE AirportDB;
```

then run `./run_all.sh` again.

### Read the audit trail

```sql
SELECT TOP 20 event_time, server_principal_name, action_id, succeeded,
       object_name, statement
FROM sys.fn_get_audit_file('/var/opt/mssql/data/AirportAudit*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
```

`succeeded = 0` shows a blocked attempt — for example the HR manager trying to
read a passport, or the security officer trying to delete a ban.

### Known limits (honest list)

- **Always Encrypted** is described in the report and selected in the design, but it is
  not scripted here: it needs a client-side certificate store and the SSMS
  "Enable Always Encrypted" workflow. TDE, Dynamic Data Masking and RLS *are* implemented.
- `sa` / `sysadmin` bypasses RLS, DDM and `DENY`; the DBA test account is a normal
  user with `db_ddladmin` + `db_backupoperator`, which is the realistic case.
- Demo passwords are in clear text in `04_security.sql`; rotate them anywhere else.
- Sample dates are relative to the day the seed is loaded, so the demo stays current.

---

## 3. Design facts used in the deck

- 19 entities in five groups: Personal (2), Operational (7), Commercial (3),
  Security (2), Workforce (6).
- 6 actors, least privilege, row-dependent rules for *own* and *assigned* data.
- DBMS: Microsoft SQL Server 2019 Developer edition.
- Sources: the Part 1 report and the course material.

/* ============================================================================
   06_tests.sql : prove the security rules, role by role.
   Each check prints PASS or FAIL. Run as sysadmin after 05.
   ============================================================================ */
USE AirportDB;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
SET NOCOUNT ON;
GO

PRINT '=== 1. Passenger: own rows only =========================================';
DECLARE @expected INT, @actual INT, @text VARCHAR(200);

SET @expected = 3;
EXECUTE AS USER = 'demo_passenger';
SET @actual = (SELECT COUNT(*) FROM Commercial.Ticket);
REVERT;
IF @actual = @expected PRINT 'PASS  passenger sees 3 own tickets'
ELSE PRINT 'FAIL  passenger sees ' + CAST(@actual AS VARCHAR(10)) + ' tickets, expected 3';

EXECUTE AS USER = 'demo_passenger';
SET @actual = (SELECT COUNT(*) FROM Commercial.Ticket WHERE PassengerID = 2);
REVERT;
IF @actual = 0 PRINT 'PASS  RLS hides another passenger''s tickets'
ELSE PRINT 'FAIL  RLS leaked ' + CAST(@actual AS VARCHAR(10)) + ' foreign tickets';

EXECUTE AS USER = 'demo_passenger';
SET @actual = (SELECT COUNT(*) FROM Personal.vw_MyProfile);
REVERT;
IF @actual = 1 PRINT 'PASS  passenger sees exactly their own profile'
ELSE PRINT 'FAIL  passenger profile rows = ' + CAST(@actual AS VARCHAR(10));

PRINT '';
PRINT '=== 2. Check-in agent: assigned flights only ===========================';
SET @expected = 8;
EXECUTE AS USER = 'demo_checkin';
SET @actual = (SELECT COUNT(*) FROM Commercial.Ticket);
REVERT;
IF @actual = @expected PRINT 'PASS  agent sees the 8 tickets of flights 1-3'
ELSE PRINT 'FAIL  agent sees ' + CAST(@actual AS VARCHAR(10)) + ' tickets, expected 8';

EXECUTE AS USER = 'demo_checkin';
SET @actual = (SELECT COUNT(*) FROM Operational.vw_AgentPassengerList);
REVERT;
IF @actual = 8 PRINT 'PASS  agent passenger list returns 8 rows'
ELSE PRINT 'FAIL  agent passenger list rows = ' + CAST(@actual AS VARCHAR(10));

EXECUTE AS USER = 'demo_checkin';
SET @actual = (SELECT COUNT(*) FROM Commercial.Ticket WHERE FlightID = 7);
REVERT;
IF @actual = 0 PRINT 'PASS  RLS hides tickets of unassigned flight 7'
ELSE PRINT 'FAIL  agent sees ' + CAST(@actual AS VARCHAR(10)) + ' unassigned tickets';

EXECUTE AS USER = 'demo_checkin';
UPDATE Commercial.Ticket SET SeatNumber = '99Z' WHERE TicketID = 9;  -- flight 7
SET @actual = @@ROWCOUNT;
REVERT;
IF @actual = 0 PRINT 'PASS  RLS block predicate prevents update outside scope'
ELSE PRINT 'FAIL  agent updated ' + CAST(@actual AS VARCHAR(10)) + ' out-of-scope rows';

EXECUTE AS USER = 'demo_checkin';
SET @actual = (SELECT IsBanned FROM Security.vw_PassengerBanStatus WHERE PassengerID = 6);
REVERT;
IF @actual = 1 PRINT 'PASS  agent sees the ban status of passenger 6'
ELSE PRINT 'FAIL  ban status for passenger 6 = ' + CAST(@actual AS VARCHAR(10));

EXECUTE AS USER = 'demo_checkin';
SET @actual = (SELECT IsBanned FROM Security.vw_PassengerBanStatus WHERE PassengerID = 4);
REVERT;
IF @actual = 0 PRINT 'PASS  expired ban is not reported as active'
ELSE PRINT 'FAIL  expired ban reported as active';

EXECUTE AS USER = 'demo_checkin';
BEGIN TRY
    SELECT @actual = COUNT(*) FROM Security.BanList;
    PRINT 'FAIL  agent can read the ban list reasons';
END TRY
BEGIN CATCH
    PRINT 'PASS  agent cannot read ban reasons';
END CATCH
REVERT;

PRINT '';
PRINT '=== 3. Check-in procedure: ban list is enforced ========================';
BEGIN TRANSACTION;
EXECUTE AS USER = 'demo_checkin';
BEGIN TRY
    EXEC Commercial.usp_CheckIn @TicketID = 7;   -- passenger 6 is banned
    PRINT 'FAIL  check-in of a banned passenger succeeded';
END TRY
BEGIN CATCH
    PRINT 'PASS  check-in of a banned passenger refused';
END CATCH
REVERT;
ROLLBACK TRANSACTION;

BEGIN TRANSACTION;
EXECUTE AS USER = 'demo_checkin';
BEGIN TRY
    EXEC Commercial.usp_CheckIn @TicketID = 1, @NewSeat = '12B', @LuggageWeightKg = 21.5;
    PRINT 'PASS  check-in of a valid passenger succeeds';
END TRY
BEGIN CATCH
    PRINT 'FAIL  valid check-in failed: ' + ERROR_MESSAGE();
END CATCH
REVERT;
ROLLBACK TRANSACTION;

PRINT '';
PRINT '=== 4. Flight coordinator: aggregate only ==============================';
SET @expected = 12;
EXECUTE AS USER = 'demo_coordinator';
SET @actual = (SELECT COUNT(*) FROM Operational.vw_FlightLoad);
REVERT;
IF @actual = @expected PRINT 'PASS  coordinator reads 12 flight-load aggregates'
ELSE PRINT 'FAIL  flight-load rows = ' + CAST(@actual AS VARCHAR(10));

EXECUTE AS USER = 'demo_coordinator';
BEGIN TRY
    SELECT @actual = COUNT(*) FROM Commercial.Ticket;
    PRINT 'FAIL  coordinator can read individual tickets';
END TRY
BEGIN CATCH
    PRINT 'PASS  coordinator denied on individual tickets';
END CATCH
REVERT;

PRINT '';
PRINT '=== 5. Security officer: full passport, no delete ======================';
EXECUTE AS USER = 'demo_security';
SET @text = (SELECT DocumentNumber FROM Personal.Passport WHERE PassportID = 1);
REVERT;
IF @text = 'P1234567' PRINT 'PASS  security officer reads the unmasked document number'
ELSE PRINT 'FAIL  unexpected value: ' + @text;

EXECUTE AS USER = 'demo_security';
BEGIN TRY
    DELETE FROM Security.BanList WHERE BanID = 1;
    PRINT 'FAIL  security officer deleted a ban entry';
END TRY
BEGIN CATCH
    PRINT 'PASS  security officer cannot delete a ban entry';
END CATCH
REVERT;

PRINT '';
PRINT '=== 6. HR manager: workforce, not passports ============================';
SET @expected = 8;
EXECUTE AS USER = 'demo_hr';
SET @actual = (SELECT COUNT(*) FROM Workforce.Employee);
REVERT;
IF @actual = @expected PRINT 'PASS  HR sees the 8 employees (including salaries)'
ELSE PRINT 'FAIL  HR sees ' + CAST(@actual AS VARCHAR(10)) + ' employees';

EXECUTE AS USER = 'demo_hr';
BEGIN TRY
    SELECT @actual = COUNT(*) FROM Personal.Passport;
    PRINT 'FAIL  HR can read passports';
END TRY
BEGIN CATCH
    PRINT 'PASS  HR denied on passports';
END CATCH
REVERT;

PRINT '';
PRINT '=== 7. DBA: structure without business data ============================';
EXECUTE AS USER = 'demo_dba';
BEGIN TRY
    SELECT @actual = COUNT(*) FROM Personal.Person;
    PRINT 'FAIL  DBA can read personal data';
END TRY
BEGIN CATCH
    PRINT 'PASS  DBA denied on personal data';
END CATCH
REVERT;

EXECUTE AS USER = 'demo_dba';
BEGIN TRY
    SELECT @actual = COUNT(*) FROM Commercial.Ticket;
    PRINT 'FAIL  DBA can read commercial data';
END TRY
BEGIN CATCH
    PRINT 'PASS  DBA denied on commercial data';
END CATCH
REVERT;

PRINT '';
PRINT '=== 8. Dynamic data masking ============================================';
EXECUTE AS USER = 'demo_reader';
SET @text = (SELECT DocumentNumber FROM Personal.Passport WHERE PassportID = 1);
REVERT;
IF @text LIKE '%****%' PRINT 'PASS  unmasked role sees a masked document number (' + @text + ')'
ELSE PRINT 'FAIL  masking did not apply: ' + @text;

EXECUTE AS USER = 'demo_security';
SET @text = (SELECT DocumentNumber FROM Personal.Passport WHERE PassportID = 1);
REVERT;
IF @text = 'P1234567' PRINT 'PASS  UNMASK restores the real value for the security officer'
ELSE PRINT 'FAIL  UNMASK did not work: ' + @text;

PRINT '';
PRINT '=== 9. Platform state ==================================================';
SELECT COUNT(*) AS TablesInFiveSchemas
FROM sys.tables
WHERE schema_id IN (SCHEMA_ID('Personal'), SCHEMA_ID('Operational'),
                    SCHEMA_ID('Commercial'), SCHEMA_ID('Security'),
                    SCHEMA_ID('Workforce'));

SELECT name, is_state_enabled AS AuditEnabled
FROM sys.server_audits WHERE name = 'AirportAudit';

SELECT name, is_state_enabled AS SpecificationEnabled
FROM sys.database_audit_specifications WHERE name = 'AirportDbAudit';

SELECT database_id, encryption_state,
       CASE encryption_state WHEN 3 THEN 'Encrypted' WHEN 2 THEN 'Encryption in progress'
                             ELSE 'Not encrypted' END AS TdeStatus
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID();

EXEC master.dbo.xp_fileexist '/var/opt/mssql/data/backups/AirportDB_full.bak';

PRINT '';
PRINT '=== End of tests =======================================================';
GO

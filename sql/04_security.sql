/* ============================================================================
   04_security.sql : authentication, roles, least-privilege grants, masking and
   row-level security.
   Demo passwords are for the local container only - change them anywhere else.
   ============================================================================ */
USE master;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ------------------------------- LOGINS ---------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'demo_passenger')
    CREATE LOGIN demo_passenger WITH PASSWORD = 'Airport#2026!Demo', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'demo_checkin')
    CREATE LOGIN demo_checkin WITH PASSWORD = 'Airport#2026!Demo', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'demo_coordinator')
    CREATE LOGIN demo_coordinator WITH PASSWORD = 'Airport#2026!Demo', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'demo_security')
    CREATE LOGIN demo_security WITH PASSWORD = 'Airport#2026!Demo', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'demo_hr')
    CREATE LOGIN demo_hr WITH PASSWORD = 'Airport#2026!Demo', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'demo_dba')
    CREATE LOGIN demo_dba WITH PASSWORD = 'Airport#2026!Demo', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'demo_reader')
    CREATE LOGIN demo_reader WITH PASSWORD = 'Airport#2026!Demo', CHECK_POLICY = OFF;
GO

USE AirportDB;
GO

/* ------------------------- USERS AND ROLES ------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'demo_passenger')
    CREATE USER demo_passenger FOR LOGIN demo_passenger;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'demo_checkin')
    CREATE USER demo_checkin FOR LOGIN demo_checkin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'demo_coordinator')
    CREATE USER demo_coordinator FOR LOGIN demo_coordinator;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'demo_security')
    CREATE USER demo_security FOR LOGIN demo_security;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'demo_hr')
    CREATE USER demo_hr FOR LOGIN demo_hr;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'demo_dba')
    CREATE USER demo_dba FOR LOGIN demo_dba;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'demo_reader')
    CREATE USER demo_reader FOR LOGIN demo_reader;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_passenger' AND type = 'R')
    EXEC('CREATE ROLE role_passenger AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_checkin_agent' AND type = 'R')
    EXEC('CREATE ROLE role_checkin_agent AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_flight_coordinator' AND type = 'R')
    EXEC('CREATE ROLE role_flight_coordinator AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_security_officer' AND type = 'R')
    EXEC('CREATE ROLE role_security_officer AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_hr_manager' AND type = 'R')
    EXEC('CREATE ROLE role_hr_manager AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'role_dba' AND type = 'R')
    EXEC('CREATE ROLE role_dba AUTHORIZATION dbo;');
GO

/* --------------------------- ROLE MEMBERSHIP ----------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'role_passenger' AND m.name = 'demo_passenger')
    ALTER ROLE role_passenger ADD MEMBER demo_passenger;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'role_checkin_agent' AND m.name = 'demo_checkin')
    ALTER ROLE role_checkin_agent ADD MEMBER demo_checkin;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'role_flight_coordinator' AND m.name = 'demo_coordinator')
    ALTER ROLE role_flight_coordinator ADD MEMBER demo_coordinator;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'role_security_officer' AND m.name = 'demo_security')
    ALTER ROLE role_security_officer ADD MEMBER demo_security;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'role_hr_manager' AND m.name = 'demo_hr')
    ALTER ROLE role_hr_manager ADD MEMBER demo_hr;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'role_dba' AND m.name = 'demo_dba')
    ALTER ROLE role_dba ADD MEMBER demo_dba;
GO

/* ------------------------ GRANTS: PASSENGER ------------------------------ */
GRANT EXECUTE ON Personal.usp_UpdateMyContact   TO role_passenger;
GRANT SELECT  ON Personal.vw_MyProfile          TO role_passenger;
GRANT SELECT  ON Commercial.vw_MyTickets        TO role_passenger;
GRANT SELECT  ON Operational.vw_MyFlights       TO role_passenger;
GRANT SELECT  ON Commercial.Ticket              TO role_passenger;   -- filtered by RLS
GO

/* ----------------------- GRANTS: CHECK-IN AGENT -------------------------- */
GRANT EXECUTE ON Commercial.usp_CheckIn         TO role_checkin_agent;
GRANT EXECUTE ON Commercial.usp_AddLuggage      TO role_checkin_agent;
GRANT SELECT  ON Operational.vw_AgentPassengerList TO role_checkin_agent;
GRANT SELECT  ON Security.vw_PassengerBanStatus TO role_checkin_agent;
GRANT SELECT  ON Commercial.Ticket              TO role_checkin_agent;  -- RLS: assigned flights
GRANT UPDATE (SeatNumber) ON Commercial.Ticket  TO role_checkin_agent;  -- RLS: assigned flights
GRANT SELECT  ON Operational.Flight (FlightID, FlightNumber, DepartureTime, Status, DelayMinutes, GateID)
      TO role_checkin_agent;
GRANT SELECT  ON Operational.Gate               TO role_checkin_agent;
GRANT SELECT  ON Operational.Terminal           TO role_checkin_agent;
GO

/* --------------------- GRANTS: FLIGHT COORDINATOR ------------------------ */
GRANT SELECT, INSERT, UPDATE ON Operational.Flight     TO role_flight_coordinator;
GRANT SELECT, INSERT, UPDATE ON Operational.CrewMember TO role_flight_coordinator;
GRANT SELECT ON Operational.Plane    TO role_flight_coordinator;
GRANT SELECT ON Operational.Route    TO role_flight_coordinator;
GRANT SELECT ON Operational.Airport  TO role_flight_coordinator;
GRANT SELECT ON Operational.Terminal TO role_flight_coordinator;
GRANT SELECT ON Operational.Gate     TO role_flight_coordinator;
GRANT SELECT ON Operational.vw_FlightLoad      TO role_flight_coordinator;
GRANT SELECT ON Workforce.vw_CrewDirectory     TO role_flight_coordinator;
GRANT EXECUTE ON Operational.usp_AssignGate    TO role_flight_coordinator;
GRANT EXECUTE ON Operational.usp_AssignCrew    TO role_flight_coordinator;
-- aggregate only: no access to who is on board
DENY SELECT ON Commercial.Ticket TO role_flight_coordinator;
DENY SELECT ON Personal.Person   TO role_flight_coordinator;
GO

/* ---------------------- GRANTS: SECURITY OFFICER ------------------------- */
GRANT SELECT ON Personal.Person     TO role_security_officer;
GRANT SELECT ON Personal.Passport   TO role_security_officer;
GRANT UNMASK TO role_security_officer;
GRANT SELECT, INSERT, UPDATE ON Security.BanList TO role_security_officer;
GRANT SELECT ON Operational.vw_FlightManifest    TO role_security_officer;
GRANT EXECUTE ON Security.usp_AddBanEntry        TO role_security_officer;
DENY DELETE ON Security.BanList TO role_security_officer;
GO

/* ------------------------- GRANTS: HR MANAGER ---------------------------- */
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Workforce TO role_hr_manager;
GRANT SELECT ON Personal.Person TO role_hr_manager;
GRANT UNMASK TO role_hr_manager;
GRANT EXECUTE ON Workforce.usp_RaiseSalary TO role_hr_manager;
DENY SELECT ON Personal.Passport TO role_hr_manager;
GO

/* ------------------- TECHNICAL TEST ACCOUNT (masking) -------------------- */
GRANT SELECT ON Personal.Passport TO demo_reader;
GO

/* --------------------------- GRANTS: DBA --------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'db_ddladmin' AND m.name = 'demo_dba')
    ALTER ROLE db_ddladmin ADD MEMBER demo_dba;
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm
               JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
               JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
               WHERE r.name = 'db_backupoperator' AND m.name = 'demo_dba')
    ALTER ROLE db_backupoperator ADD MEMBER demo_dba;
GRANT VIEW DEFINITION TO role_dba;
DENY SELECT ON Personal.Person      TO role_dba;
DENY SELECT ON Personal.Passport    TO role_dba;
DENY SELECT ON Commercial.Passenger TO role_dba;
DENY SELECT ON Commercial.Ticket    TO role_dba;
DENY SELECT ON Workforce.Employee   TO role_dba;
DENY SELECT ON Security.BanList     TO role_dba;
GO

/* ------------------------------ MASKING ---------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.masked_columns
               WHERE object_id = OBJECT_ID('Personal.Passport') AND name = 'DocumentNumber')
    EXEC(N'ALTER TABLE Personal.Passport ALTER COLUMN DocumentNumber ADD MASKED WITH (FUNCTION = ''partial(2,"****",2)'');');

IF NOT EXISTS (SELECT 1 FROM sys.masked_columns
               WHERE object_id = OBJECT_ID('Personal.Person') AND name = 'Email')
    EXEC(N'ALTER TABLE Personal.Person ALTER COLUMN Email ADD MASKED WITH (FUNCTION = ''email()'');');

IF NOT EXISTS (SELECT 1 FROM sys.masked_columns
               WHERE object_id = OBJECT_ID('Personal.Person') AND name = 'PhoneNumber')
    EXEC(N'ALTER TABLE Personal.Person ALTER COLUMN PhoneNumber ADD MASKED WITH (FUNCTION = ''partial(3,"****",2)'');');
GO

/* -------------------------- ROW-LEVEL SECURITY --------------------------- */
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'TicketAccessPolicy')
    DROP SECURITY POLICY Security.TicketAccessPolicy;
IF OBJECT_ID('Security.fn_TicketFilter') IS NOT NULL
    DROP FUNCTION Security.fn_TicketFilter;
GO

CREATE FUNCTION Security.fn_TicketFilter (@PassengerID INT, @FlightID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS Allowed
    WHERE USER_NAME() = 'dbo'
       OR EXISTS (SELECT 1 FROM Security.UserAccount AS ua
                  WHERE ua.LoginName = USER_NAME()
                    AND ua.PassengerID = @PassengerID)
       OR EXISTS (SELECT 1 FROM Security.AgentFlightAssignment AS a
                  WHERE a.LoginName = USER_NAME()
                    AND a.FlightID = @FlightID);
GO

CREATE SECURITY POLICY Security.TicketAccessPolicy
    ADD FILTER PREDICATE Security.fn_TicketFilter(PassengerID, FlightID) ON Commercial.Ticket,
    ADD BLOCK PREDICATE  Security.fn_TicketFilter(PassengerID, FlightID) ON Commercial.Ticket AFTER INSERT,
    ADD BLOCK PREDICATE  Security.fn_TicketFilter(PassengerID, FlightID) ON Commercial.Ticket AFTER UPDATE
WITH (STATE = ON);
GO

PRINT 'Logins, roles, grants, masking and RLS configured.';
GO

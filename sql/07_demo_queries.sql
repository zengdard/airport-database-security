/* ============================================================================
   07_demo_queries.sql : queries to show during the defence.
   Read-only: nothing here changes the data.
   ============================================================================ */
USE AirportDB;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
SET NOCOUNT ON;
GO

PRINT '--- Row counts ----------------------------------------------------------';
SELECT 'Person' AS Entity, COUNT(*) AS Rows FROM Personal.Person
UNION ALL SELECT 'Passport',      COUNT(*) FROM Personal.Passport
UNION ALL SELECT 'Flight',        COUNT(*) FROM Operational.Flight
UNION ALL SELECT 'Ticket',        COUNT(*) FROM Commercial.Ticket
UNION ALL SELECT 'Luggage',       COUNT(*) FROM Commercial.Luggage
UNION ALL SELECT 'Employee',      COUNT(*) FROM Workforce.Employee
UNION ALL SELECT 'BanList',       COUNT(*) FROM Security.BanList;

PRINT '';
PRINT '--- Flights with load factor (coordinator view) -------------------------';
SELECT FlightNumber, CONVERT(VARCHAR(16), DepartureTime, 120) AS Departure,
       SeatCount, TicketsSold, LoadPercent
FROM Operational.vw_FlightLoad
ORDER BY DepartureTime;

PRINT '';
PRINT '--- Active bans ---------------------------------------------------------';
SELECT b.BanID, pe.FirstName + ' ' + pe.LastName AS Passenger,
       b.ActiveFrom, b.ActiveTo, e.Position AS AddedBy
FROM Security.BanList AS b
JOIN Commercial.Passenger AS pa ON pa.PassengerID = b.PassengerID
JOIN Personal.Person AS pe ON pe.PersonID = pa.PersonID
JOIN Workforce.Employee AS e ON e.EmployeeID = b.AddedByEmployeeID
WHERE CAST(SYSUTCDATETIME() AS date) BETWEEN b.ActiveFrom AND b.ActiveTo;

PRINT '';
PRINT '--- Expired professional licences (a real finding) ----------------------';
SELECT pe.FirstName + ' ' + pe.LastName AS Employee, l.Name AS Licence,
       el.ExpiryDate
FROM Workforce.EmployeeLicense AS el
JOIN Workforce.Employee AS e ON e.EmployeeID = el.EmployeeID
JOIN Personal.Person AS pe ON pe.PersonID = e.PersonID
JOIN Workforce.License AS l ON l.LicenseID = el.LicenseID
WHERE el.ExpiryDate < CAST(SYSUTCDATETIME() AS date);

PRINT '';
PRINT '--- Audit trail: who read or changed sensitive data ---------------------';
SELECT TOP 12
       event_time, server_principal_name AS LoginName,
       action_id, succeeded, object_name AS ObjectName,
       LEFT(statement, 90) AS Statement
FROM sys.fn_get_audit_file('/var/opt/mssql/data/AirportAudit*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
GO

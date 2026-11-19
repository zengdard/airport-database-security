/* ============================================================================
   03_views_procedures.sql : the application surface.
   Row-dependent rules ("own" / "assigned") are implemented with filtered views
   and stored procedures owned by dbo, so the caller needs no table permission.
   ============================================================================ */
USE AirportDB;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ------------------------------- VIEWS ----------------------------------- */

CREATE OR ALTER VIEW Personal.vw_MyProfile
AS
SELECT p.PersonID, p.FirstName, p.MiddleName, p.LastName, p.DateOfBirth,
       p.PlaceOfBirth, p.Sex, p.PhoneNumber, p.Email, p.ResidentialAddress
FROM Personal.Person AS p
WHERE EXISTS (SELECT 1
              FROM Security.UserAccount AS ua
              JOIN Commercial.Passenger AS pa ON pa.PassengerID = ua.PassengerID
              WHERE ua.LoginName = USER_NAME() AND pa.PersonID = p.PersonID)
   OR EXISTS (SELECT 1
              FROM Security.UserAccount AS ua
              JOIN Workforce.Employee AS e ON e.EmployeeID = ua.EmployeeID
              WHERE ua.LoginName = USER_NAME() AND e.PersonID = p.PersonID);
GO

CREATE OR ALTER VIEW Commercial.vw_MyTickets
AS
SELECT t.TicketID, t.TicketNumber, f.FlightNumber, f.DepartureTime, f.Status,
       o.IATACode AS Origin, d.IATACode AS Destination,
       t.Class, t.SeatNumber, t.Price
FROM Commercial.Ticket AS t
JOIN Operational.Flight AS f ON f.FlightID = t.FlightID
JOIN Operational.Route AS r ON r.RouteID = f.RouteID
JOIN Operational.Airport AS o ON o.AirportID = r.OriginAirportID
JOIN Operational.Airport AS d ON d.AirportID = r.DestinationAirportID
WHERE t.PassengerID = (SELECT ua.PassengerID
                       FROM Security.UserAccount AS ua
                       WHERE ua.LoginName = USER_NAME());
GO

CREATE OR ALTER VIEW Operational.vw_MyFlights
AS
SELECT DISTINCT f.FlightID, f.FlightNumber, f.DepartureTime, f.Status,
       f.DelayMinutes, g.GateNumber, tm.Name AS Terminal
FROM Operational.Flight AS f
JOIN Commercial.Ticket AS t ON t.FlightID = f.FlightID
LEFT JOIN Operational.Gate AS g ON g.GateID = f.GateID
LEFT JOIN Operational.Terminal AS tm ON tm.TerminalID = g.TerminalID
WHERE t.PassengerID = (SELECT ua.PassengerID
                       FROM Security.UserAccount AS ua
                       WHERE ua.LoginName = USER_NAME());
GO

CREATE OR ALTER VIEW Operational.vw_AgentPassengerList
AS
SELECT f.FlightNumber, f.DepartureTime, t.TicketID, t.SeatNumber, t.Class,
       pa.PassengerID, pe.FirstName, pe.LastName
FROM Security.AgentFlightAssignment AS a
JOIN Operational.Flight AS f ON f.FlightID = a.FlightID
JOIN Commercial.Ticket AS t ON t.FlightID = f.FlightID
JOIN Commercial.Passenger AS pa ON pa.PassengerID = t.PassengerID
JOIN Personal.Person AS pe ON pe.PersonID = pa.PersonID
WHERE a.LoginName = USER_NAME();
GO

CREATE OR ALTER VIEW Operational.vw_FlightManifest
AS
SELECT f.FlightNumber, f.DepartureTime, t.TicketID, t.SeatNumber,
       pe.FirstName, pe.LastName, pa.PassengerID,
       CASE WHEN EXISTS (SELECT 1 FROM Security.BanList AS b
                         WHERE b.PassengerID = pa.PassengerID
                           AND CAST(SYSUTCDATETIME() AS date) BETWEEN b.ActiveFrom AND b.ActiveTo)
            THEN 1 ELSE 0 END AS IsBanned
FROM Operational.Flight AS f
JOIN Commercial.Ticket AS t ON t.FlightID = f.FlightID
JOIN Commercial.Passenger AS pa ON pa.PassengerID = t.PassengerID
JOIN Personal.Person AS pe ON pe.PersonID = pa.PersonID;
GO

CREATE OR ALTER VIEW Operational.vw_FlightLoad
AS
SELECT f.FlightID, f.FlightNumber, f.DepartureTime, pl.SeatCount,
       COUNT(t.TicketID) AS TicketsSold,
       CAST(COUNT(t.TicketID) * 100.0 / pl.SeatCount AS DECIMAL(5,1)) AS LoadPercent
FROM Operational.Flight AS f
JOIN Operational.Plane AS pl ON pl.PlaneID = f.PlaneID
LEFT JOIN Commercial.Ticket AS t ON t.FlightID = f.FlightID
GROUP BY f.FlightID, f.FlightNumber, f.DepartureTime, pl.SeatCount;
GO

CREATE OR ALTER VIEW Security.vw_PassengerBanStatus
AS
SELECT pa.PassengerID, pe.FirstName, pe.LastName,
       CASE WHEN EXISTS (SELECT 1 FROM Security.BanList AS b
                         WHERE b.PassengerID = pa.PassengerID
                           AND CAST(SYSUTCDATETIME() AS date) BETWEEN b.ActiveFrom AND b.ActiveTo)
            THEN 1 ELSE 0 END AS IsBanned
FROM Commercial.Passenger AS pa
JOIN Personal.Person AS pe ON pe.PersonID = pa.PersonID;
GO

CREATE OR ALTER VIEW Workforce.vw_CrewDirectory
AS
SELECT e.EmployeeID, pe.FirstName, pe.LastName, e.Position,
       ae.FlightHours,
       (SELECT COUNT(*) FROM Operational.CrewMember AS cm
        WHERE cm.AirEmployeeID = e.EmployeeID) AS Assignments
FROM Workforce.Employee AS e
JOIN Personal.Person AS pe ON pe.PersonID = e.PersonID
JOIN Workforce.AirEmployee AS ae ON ae.EmployeeID = e.EmployeeID;
GO

/* ---------------------------- STORED PROCEDURES -------------------------- */

CREATE OR ALTER PROCEDURE Personal.usp_UpdateMyContact
    @PhoneNumber VARCHAR(30)    = NULL,
    @Email       NVARCHAR(254)  = NULL,
    @Address     NVARCHAR(255)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF IS_ROLEMEMBER('role_passenger') <> 1
        THROW 51000, 'Only a passenger can update their own contact data.', 1;

    DECLARE @PassengerID INT =
        (SELECT PassengerID FROM Security.UserAccount WHERE LoginName = USER_NAME());

    IF @PassengerID IS NULL
        THROW 51001, 'No passenger account is linked to this login.', 1;

    UPDATE Personal.Person
    SET PhoneNumber        = COALESCE(@PhoneNumber, PhoneNumber),
        Email              = COALESCE(@Email, Email),
        ResidentialAddress = COALESCE(@Address, ResidentialAddress)
    WHERE PersonID = (SELECT PersonID FROM Commercial.Passenger
                      WHERE PassengerID = @PassengerID);
END
GO

CREATE OR ALTER PROCEDURE Commercial.usp_CheckIn
    @TicketID        INT,
    @NewSeat         VARCHAR(5)   = NULL,
    @LuggageWeightKg DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF IS_ROLEMEMBER('role_checkin_agent') <> 1
        THROW 51010, 'Only a check-in agent can check in a passenger.', 1;

    DECLARE @FlightID INT, @PassengerID INT;
    SELECT @FlightID = FlightID, @PassengerID = PassengerID
    FROM Commercial.Ticket WHERE TicketID = @TicketID;

    IF @FlightID IS NULL
        THROW 51011, 'Ticket not found.', 1;

    IF NOT EXISTS (SELECT 1 FROM Security.AgentFlightAssignment
                   WHERE LoginName = USER_NAME() AND FlightID = @FlightID)
        THROW 51012, 'This flight is not assigned to you.', 1;

    IF EXISTS (SELECT 1 FROM Security.BanList
               WHERE PassengerID = @PassengerID
                 AND CAST(SYSUTCDATETIME() AS date) BETWEEN ActiveFrom AND ActiveTo)
        THROW 51013, 'Passenger is on the ban list - check-in refused.', 1;

    IF @NewSeat IS NOT NULL
        UPDATE Commercial.Ticket SET SeatNumber = @NewSeat WHERE TicketID = @TicketID;

    IF @LuggageWeightKg IS NOT NULL
        INSERT INTO Commercial.Luggage (TicketID, WeightKg)
        VALUES (@TicketID, @LuggageWeightKg);
END
GO

CREATE OR ALTER PROCEDURE Commercial.usp_AddLuggage
    @TicketID INT,
    @WeightKg DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF IS_ROLEMEMBER('role_checkin_agent') <> 1
        THROW 51020, 'Only a check-in agent can register luggage.', 1;

    IF NOT EXISTS (SELECT 1
                   FROM Commercial.Ticket AS t
                   JOIN Security.AgentFlightAssignment AS a ON a.FlightID = t.FlightID
                   WHERE t.TicketID = @TicketID AND a.LoginName = USER_NAME())
        THROW 51021, 'This ticket is not on one of your flights.', 1;

    INSERT INTO Commercial.Luggage (TicketID, WeightKg) VALUES (@TicketID, @WeightKg);
END
GO

CREATE OR ALTER PROCEDURE Security.usp_AddBanEntry
    @PassengerID INT,
    @ActiveFrom  DATE,
    @ActiveTo    DATE,
    @Reason      NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    IF IS_ROLEMEMBER('role_security_officer') <> 1
        THROW 51030, 'Only a security officer can modify the ban list.', 1;
    IF @ActiveTo <= @ActiveFrom
        THROW 51031, 'The end date must be after the start date.', 1;

    DECLARE @EmployeeID INT =
        (SELECT EmployeeID FROM Security.UserAccount WHERE LoginName = USER_NAME());
    IF @EmployeeID IS NULL
        THROW 51032, 'No employee account is linked to this login.', 1;

    INSERT INTO Security.BanList (PassengerID, AddedByEmployeeID, ActiveFrom, ActiveTo, Reason)
    VALUES (@PassengerID, @EmployeeID, @ActiveFrom, @ActiveTo, @Reason);
END
GO

CREATE OR ALTER PROCEDURE Operational.usp_AssignGate
    @FlightID INT,
    @GateID   INT
AS
BEGIN
    SET NOCOUNT ON;
    IF IS_ROLEMEMBER('role_flight_coordinator') <> 1
        THROW 51040, 'Only a flight coordinator can assign a gate.', 1;

    UPDATE Operational.Flight SET GateID = @GateID WHERE FlightID = @FlightID;
    IF @@ROWCOUNT = 0
        THROW 51041, 'Flight not found.', 1;
END
GO

CREATE OR ALTER PROCEDURE Operational.usp_AssignCrew
    @FlightID      INT,
    @AirEmployeeID INT,
    @CrewRole      VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    IF IS_ROLEMEMBER('role_flight_coordinator') <> 1
        THROW 51050, 'Only a flight coordinator can assign crew.', 1;
    IF @CrewRole NOT IN ('CAPTAIN','FIRST_OFFICER','PURSER','CABIN_CREW')
        THROW 51051, 'Invalid crew role.', 1;

    INSERT INTO Operational.CrewMember (FlightID, AirEmployeeID, CrewRole)
    VALUES (@FlightID, @AirEmployeeID, @CrewRole);
END
GO

CREATE OR ALTER PROCEDURE Workforce.usp_RaiseSalary
    @EmployeeID INT,
    @NewSalary  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF IS_ROLEMEMBER('role_hr_manager') <> 1
        THROW 51060, 'Only an HR manager can change a salary.', 1;
    IF @NewSalary < 0
        THROW 51061, 'Salary cannot be negative.', 1;

    UPDATE Workforce.Employee SET Salary = @NewSalary WHERE EmployeeID = @EmployeeID;
    IF @@ROWCOUNT = 0
        THROW 51062, 'Employee not found.', 1;
END
GO

PRINT 'Views and stored procedures created.';
GO

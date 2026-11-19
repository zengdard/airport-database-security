/* ============================================================================
   02_seed.sql : realistic sample data for the airport database.
   Run once, after 01_schema.sql. Dates are relative to the current date so the
   demo stays meaningful.
   ============================================================================ */
USE AirportDB;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM Personal.Person)
BEGIN
    PRINT 'Seed data already present - 02_seed.sql skipped.';
    RETURN;
END
GO

DECLARE @today DATE = CAST(SYSUTCDATETIME() AS DATE);
DECLARE @d1 DATE = DATEADD(day, 1, @today);
DECLARE @d2 DATE = DATEADD(day, 2, @today);

/* ------------------------------- PERSONAL -------------------------------- */
SET IDENTITY_INSERT Personal.Person ON;
INSERT INTO Personal.Person
    (PersonID, FirstName, MiddleName, LastName, DateOfBirth, PlaceOfBirth, Sex,
     PhoneNumber, Email, ResidentialAddress)
VALUES
 ( 1, N'Anna',    NULL,   N'Weber',    '1990-03-12', N'Luxembourg',  'F', '+352 621 100 201', N'anna.weber@example.lu',    N'12 rue de la Gare, L-1611 Luxembourg'),
 ( 2, N'Marc',    N'Paul', N'Dubois',   '1985-07-02', N'Paris',       'M', '+33 6 12 34 56 78', N'marc.dubois@example.fr',   N'8 rue Oberkampf, F-75011 Paris'),
 ( 3, N'Sofia',   NULL,   N'Rossi',    '1993-11-25', N'Rome',        'F', '+39 333 987 6543', N'sofia.rossi@example.it',   N'Via Roma 42, I-00184 Roma'),
 ( 4, N'Liam',    NULL,   N'O''Connor', '1979-05-18', N'Dublin',     'M', '+353 87 123 4567', N'liam.oconnor@example.ie',  N'15 Grafton Street, Dublin 2'),
 ( 5, N'Yuki',    NULL,   N'Tanaka',   '1996-01-30', N'Osaka',       'F', '+81 90 1234 5678', N'yuki.tanaka@example.jp',   N'2-4-1 Umeda, Osaka 530-0001'),
 ( 6, N'Omar',    NULL,   N'Haddad',   '1988-09-09', N'Beirut',      'M', '+961 3 456 789',   N'omar.haddad@example.lb',   N'Rue Hamra 22, Beirut'),
 ( 7, N'Elena',   N'Ivanova', N'Petrova', '1984-04-21', N'Sofia',    'F', '+359 88 765 4321', N'elena.petrova@example.bg', N'12 Vitosha Blvd, Sofia'),
 ( 8, N'Noah',    NULL,   N'Martin',   '2001-12-05', N'Montreal',    'M', '+1 514 555 0142',  N'noah.martin@example.ca',   N'3400 rue Saint-Denis, Montreal'),
 ( 9, N'Claire',  NULL,   N'Muller',   '1992-02-14', N'Luxembourg',  'F', '+352 621 100 202', N'claire.muller@airport.lu', N'5 avenue de la Liberté, L-1931 Luxembourg'),
 (10, N'Jan',     NULL,   N'Kowalski', '1987-06-30', N'Krakow',      'M', '+48 601 234 567',  N'jan.kowalski@airport.lu',  N'ul. Dluga 10, PL-31-147 Krakow'),
 (11, N'Fatima',  NULL,   N'Zahra',    '1981-08-19', N'Casablanca',  'F', '+212 6 61 23 45 67', N'fatima.zahra@airport.lu', N'22 bd Zerktouni, Casablanca'),
 (12, N'Thomas',  NULL,   N'Becker',   '1978-10-11', N'Trier',       'M', '+49 151 2345 6789', N'thomas.becker@airport.lu', N'Porta Nigra 3, D-54290 Trier'),
 (13, N'David',   NULL,   N'Chen',     '1983-03-27', N'Taipei',      'M', '+886 912 345 678', N'david.chen@airport.lu',    N'No. 7, Xinyi Rd, Taipei'),
 (14, N'Aisha',   NULL,   N'Bello',    '1994-07-16', N'Lagos',       'F', '+234 803 123 4567', N'aisha.bello@airport.lu',  N'14 Adeola Odeku St, Lagos'),
 (15, N'Lucas',   NULL,   N'Silva',    '1997-09-03', N'Porto',       'M', '+351 912 345 678', N'lucas.silva@airport.lu',   N'Rua de Cedofeita 88, Porto');
SET IDENTITY_INSERT Personal.Person OFF;

SET IDENTITY_INSERT Personal.Passport ON;
INSERT INTO Personal.Passport
    (PassportID, PersonID, DocumentType, DocumentNumber, IssuingCountry, Nationality, IssueDate, ExpiryDate)
VALUES
 ( 1,  1, 'PASSPORT', 'P1234567', 'LU', 'LU', '2019-05-10', '2029-05-10'),
 ( 2,  2, 'PASSPORT', '18FR45678','FR', 'FR', '2020-02-14', '2030-02-14'),
 ( 3,  3, 'ID_CARD',  'C1234567', 'IT', 'IT', '2021-06-01', '2031-06-01'),
 ( 4,  4, 'PASSPORT', 'IE9876543','IE', 'IE', '2018-09-20', '2028-09-20'),
 ( 5,  5, 'PASSPORT', 'JP7654321','JP', 'JP', '2022-01-15', '2032-01-15'),
 ( 6,  6, 'PASSPORT', 'LB1122334','LB', 'LB', '2017-11-11', '2027-11-11'),
 ( 7,  7, 'PASSPORT', 'BG5566778','BG', 'BG', '2021-03-30', '2031-03-30'),
 ( 8,  8, 'PASSPORT', 'CA3344556','CA', 'CA', '2023-07-07', '2033-07-07'),
 ( 9,  9, 'ID_CARD',  'LU9988776','LU', 'LU', '2020-10-10', '2030-10-10'),
 (10, 10, 'PASSPORT', 'PL4455667','PL', 'PL', '2019-12-01', '2029-12-01'),
 (11, 11, 'PASSPORT', 'MA7788990','MA', 'MA', '2018-04-04', '2028-04-04'),
 (12, 12, 'ID_CARD',  'DE6677889','DE', 'DE', '2022-08-08', '2032-08-08'),
 (13, 13, 'PASSPORT', 'TW2233445','TW', 'TW', '2020-05-05', '2030-05-05'),
 (14, 14, 'PASSPORT', 'NG8899001','NG', 'NG', '2021-09-09', '2031-09-09'),
 (15, 15, 'PASSPORT', 'PT5566778','PT', 'PT', '2023-02-02', '2033-02-02');
SET IDENTITY_INSERT Personal.Passport OFF;

/* ------------------------------ OPERATIONAL ------------------------------ */
SET IDENTITY_INSERT Operational.Airport ON;
INSERT INTO Operational.Airport
    (AirportID, IATACode, Name, Country, City, TimeZone, ContactPhone, Address)
VALUES
 ( 1, 'LUX', N'Luxembourg Airport',        N'Luxembourg',     N'Luxembourg', N'Europe/Luxembourg', '+352 2464 1',        N'Rue de Trèves, L-2632 Findel'),
 ( 2, 'LHR', N'London Heathrow',           N'United Kingdom', N'London',     N'Europe/London',     '+44 20 8759 4321',   N'Longford, Hounslow TW6'),
 ( 3, 'CDG', N'Paris Charles de Gaulle',   N'France',         N'Paris',      N'Europe/Paris',      '+33 1 70 36 39 50',  N'95700 Roissy-en-France'),
 ( 4, 'FRA', N'Frankfurt Airport',         N'Germany',        N'Frankfurt',  N'Europe/Berlin',     '+49 69 690 0',       N'60547 Frankfurt am Main'),
 ( 5, 'AMS', N'Amsterdam Schiphol',        N'Netherlands',    N'Amsterdam',  N'Europe/Amsterdam',  '+31 20 794 0800',    N'Evert van de Beekstraat 202'),
 ( 6, 'MAD', N'Madrid Barajas',            N'Spain',          N'Madrid',     N'Europe/Madrid',     '+34 91 321 10 00',   N'28042 Madrid'),
 ( 7, 'ZRH', N'Zurich Airport',            N'Switzerland',    N'Zurich',     N'Europe/Zurich',     '+41 43 816 22 11',   N'8058 Zürich-Flughafen'),
 ( 8, 'JFK', N'New York John F. Kennedy',  N'United States',  N'New York',   N'America/New_York',  '+1 718 244 4444',    N'Queens, NY 11430'),
 ( 9, 'DXB', N'Dubai International',       N'United Arab Emirates', N'Dubai', N'Asia/Dubai',      '+971 4 224 5555',    N'Dubai International Airport'),
 (10, 'IST', N'Istanbul Airport',          N'Türkiye',        N'Istanbul',   N'Europe/Istanbul',   '+90 444 1 442',      N'Tayakadın, Arnavutköy');
SET IDENTITY_INSERT Operational.Airport OFF;

SET IDENTITY_INSERT Operational.Route ON;
INSERT INTO Operational.Route (RouteID, OriginAirportID, DestinationAirportID, ExpectedDurationMinutes)
VALUES
 (1, 1,  2,  95), (2, 1,  3,  80), (3, 1,  4,  75),
 (4, 1,  5, 105), (5, 1,  6, 155), (6, 1,  7,  70),
 (7, 1,  8, 510), (8, 1,  9, 405), (9, 1, 10, 215),
 (10, 8, 1, 495);
SET IDENTITY_INSERT Operational.Route OFF;

SET IDENTITY_INSERT Operational.Plane ON;
INSERT INTO Operational.Plane (PlaneID, Model, SeatCount, InServiceSince)
VALUES
 (1, N'Airbus A320neo',   180, '2021-03-15'),
 (2, N'Boeing 737-800',   189, '2018-09-01'),
 (3, N'Embraer E195',     122, '2019-06-12'),
 (4, N'Airbus A321neo',   220, '2023-01-20'),
 (5, N'Boeing 787-9',     296, '2020-11-05');
SET IDENTITY_INSERT Operational.Plane OFF;

SET IDENTITY_INSERT Operational.Terminal ON;
INSERT INTO Operational.Terminal (TerminalID, AirportID, Name)
VALUES (1, 1, N'Terminal A'), (2, 1, N'Terminal B');
SET IDENTITY_INSERT Operational.Terminal OFF;

SET IDENTITY_INSERT Operational.Gate ON;
INSERT INTO Operational.Gate (GateID, TerminalID, GateNumber)
VALUES
 (1,1,'A01'),(2,1,'A02'),(3,1,'A03'),(4,1,'A04'),(5,1,'A05'),(6,1,'A06'),
 (7,2,'B01'),(8,2,'B02'),(9,2,'B03'),(10,2,'B04'),(11,2,'B05'),(12,2,'B06');
SET IDENTITY_INSERT Operational.Gate OFF;

SET IDENTITY_INSERT Operational.Flight ON;
INSERT INTO Operational.Flight
    (FlightID, FlightNumber, DepartureTime, Status, DelayMinutes, PlaneID, RouteID, GateID)
VALUES
 ( 1, 'LX101', DATEADD(hour,  8, CAST(@d1 AS DATETIME2(0))), 'BOARDING',  0, 1, 1,  1),
 ( 2, 'LX102', DATEADD(hour,  9, CAST(@d1 AS DATETIME2(0))), 'SCHEDULED', 0, 3, 2,  7),
 ( 3, 'LX103', DATEADD(hour, 10, CAST(@d1 AS DATETIME2(0))), 'SCHEDULED', 0, 2, 3,  2),
 ( 4, 'LX104', DATEADD(hour, 12, CAST(@d1 AS DATETIME2(0))), 'SCHEDULED', 0, 1, 4,  8),
 ( 5, 'LX105', DATEADD(hour, 14, CAST(@d1 AS DATETIME2(0))), 'DELAYED',  25, 3, 5,  3),
 ( 6, 'LX106', DATEADD(hour, 16, CAST(@d1 AS DATETIME2(0))), 'SCHEDULED', 0, 2, 6,  9),
 ( 7, 'LX107', DATEADD(hour, 18, CAST(@d1 AS DATETIME2(0))), 'SCHEDULED', 0, 5, 7,  4),
 ( 8, 'LX108', DATEADD(hour,  2, CAST(@d2 AS DATETIME2(0))), 'SCHEDULED', 0, 5, 8, 10),
 ( 9, 'LX109', DATEADD(hour,  6, CAST(@d2 AS DATETIME2(0))), 'SCHEDULED', 0, 3, 9,  6),
 (10, 'LX110', DATEADD(hour,  7, CAST(@d2 AS DATETIME2(0))), 'SCHEDULED', 0, 2, 1,  5),
 (11, 'LX111', DATEADD(hour,  9, CAST(@d2 AS DATETIME2(0))), 'CANCELLED', 0, 3, 2, 11),
 (12, 'LX112', DATEADD(hour, 11, CAST(@d2 AS DATETIME2(0))), 'BOARDING',  0, 1, 3, 12);
SET IDENTITY_INSERT Operational.Flight OFF;

/* ------------------------------- WORKFORCE ------------------------------- */
SET IDENTITY_INSERT Workforce.Department ON;
INSERT INTO Workforce.Department (DepartmentID, TerminalID, DepartmentType, Name)
VALUES
 (1, 1, 'CHECK_IN',    N'Check-in and boarding'),
 (2, 1, 'SECURITY',    N'Airport security'),
 (3, 2, 'HUMAN_RESOURCES', N'Human resources'),
 (4, 2, 'OPERATIONS',  N'Flight operations');
SET IDENTITY_INSERT Workforce.Department OFF;

SET IDENTITY_INSERT Workforce.Employee ON;
INSERT INTO Workforce.Employee (EmployeeID, PersonID, HireDate, Position, Salary, WorkSchedule)
VALUES
 (1,  9, '2018-04-01', N'Check-in agent',     42000.00, N'Shift A 06:00-14:00'),
 (2, 10, '2016-09-15', N'Security officer',   48000.00, N'Shift B 14:00-22:00'),
 (3, 11, '2014-01-10', N'HR manager',         68000.00, N'Office hours'),
 (4, 12, '2012-05-20', N'Flight coordinator', 62000.00, N'Office hours'),
 (5,  7, '2010-08-01', N'Captain',           115000.00, N'Rotating roster'),
 (6, 13, '2015-02-17', N'First officer',      78000.00, N'Rotating roster'),
 (7, 14, '2019-06-03', N'Cabin crew',         39000.00, N'Rotating roster'),
 (8, 15, '2021-09-27', N'Cabin crew',         37000.00, N'Rotating roster');
SET IDENTITY_INSERT Workforce.Employee OFF;

INSERT INTO Workforce.GroundEmployee (EmployeeID, DepartmentID)
VALUES (1,1), (2,2), (3,3), (4,4);

INSERT INTO Workforce.AirEmployee (EmployeeID, FlightHours)
VALUES (5,12500), (6,6400), (7,3100), (8,1450);

SET IDENTITY_INSERT Workforce.License ON;
INSERT INTO Workforce.License (LicenseID, Name, Category)
VALUES
 (1, N'Airline Transport Pilot Licence', 'FLIGHT_CREW'),
 (2, N'Cabin Crew Attestation',          'CABIN_CREW'),
 (3, N'Dangerous Goods Awareness',       'GROUND'),
 (4, N'Airport Security Clearance',      'SECURITY'),
 (5, N'First Aid Certificate',           'GROUND');
SET IDENTITY_INSERT Workforce.License OFF;

SET IDENTITY_INSERT Workforce.EmployeeLicense ON;
INSERT INTO Workforce.EmployeeLicense
    (EmployeeLicenseID, EmployeeID, LicenseID, IssueDate, ExpiryDate)
VALUES
 (1, 5, 1, '2015-01-01', '2027-01-01'),
 (2, 6, 1, '2016-03-01', '2028-03-01'),
 (3, 7, 2, '2019-06-01', '2027-06-01'),
 (4, 8, 2, '2021-10-01', '2026-10-01'),  -- expired: finds a real gap
 (5, 2, 4, '2023-01-15', '2028-01-15'),
 (6, 1, 3, '2024-02-01', '2027-02-01'),
 (7, 2, 5, '2025-05-01', '2028-05-01'),
 (8, 7, 5, '2025-06-01', '2028-06-01');
SET IDENTITY_INSERT Workforce.EmployeeLicense OFF;

SET IDENTITY_INSERT Operational.CrewMember ON;
INSERT INTO Operational.CrewMember (CrewMemberID, FlightID, AirEmployeeID, CrewRole)
VALUES
 (1, 1, 5, 'CAPTAIN'),
 (2, 1, 7, 'PURSER'),
 (3, 1, 8, 'CABIN_CREW'),
 (4, 2, 6, 'CAPTAIN'),
 (5, 2, 8, 'CABIN_CREW'),
 (6, 3, 5, 'CAPTAIN'),
 (7, 3, 7, 'CABIN_CREW'),
 (8, 7, 5, 'CAPTAIN'),
 (9, 7, 7, 'PURSER'),
 (10, 7, 8, 'CABIN_CREW'),
 (11, 8, 6, 'CAPTAIN'),
 (12, 8, 8, 'CABIN_CREW'),
 (13, 9, 5, 'CAPTAIN'),
 (14, 9, 7, 'CABIN_CREW'),
 (15, 12, 6, 'CAPTAIN'),
 (16, 12, 7, 'PURSER');
SET IDENTITY_INSERT Operational.CrewMember OFF;

/* ------------------------------- COMMERCIAL ------------------------------ */
SET IDENTITY_INSERT Commercial.Passenger ON;
INSERT INTO Commercial.Passenger
    (PassengerID, PersonID, FrequentFlyerNumber, MilesBalance, SpecialAssistance)
VALUES
 (1, 1, 'LX-100200300', 24500, NULL),
 (2, 2, NULL,            1200, NULL),
 (3, 3, 'LX-100200301', 88000, NULL),
 (4, 4, 'LX-100200302',  4300, N'Wheelchair assistance at the gate'),
 (5, 5, NULL,               0, NULL),
 (6, 6, NULL,               0, NULL),
 (7, 7, 'LX-100200303', 15600, NULL),
 (8, 8, NULL,             350, N'Nut allergy');
SET IDENTITY_INSERT Commercial.Passenger OFF;

SET IDENTITY_INSERT Commercial.Ticket ON;
INSERT INTO Commercial.Ticket
    (TicketID, TicketNumber, PassengerID, FlightID, Price, Class, SeatNumber)
VALUES
 ( 1, '1000000001', 1,  1, 120.00, 'ECONOMY',  '12A'),
 ( 2, '1000000002', 2,  1, 145.00, 'ECONOMY',  '14C'),
 ( 3, '1000000003', 3,  1, 420.00, 'BUSINESS', '2A'),
 ( 4, '1000000004', 1,  2,  95.00, 'ECONOMY',  '8F'),
 ( 5, '1000000005', 4,  2, 110.00, 'ECONOMY',  '9A'),
 ( 6, '1000000006', 5,  3, 130.00, 'ECONOMY',  '11B'),
 ( 7, '1000000007', 6,  3, 130.00, 'ECONOMY',  '11C'),
 ( 8, '1000000008', 2,  4,  99.00, 'ECONOMY',  '7D'),
 ( 9, '1000000009', 3,  7, 890.00, 'BUSINESS', '3A'),
 (10, '1000000010', 7, 10, 390.00, 'BUSINESS', '2C'),
 (11, '1000000011', 8,  8, 640.00, 'ECONOMY',  '22A'),
 (12, '1000000012', 1, 10,  88.00, 'ECONOMY',  '15A'),
 (13, '1000000013', 5, 10,  88.00, 'ECONOMY',  '15B'),
 (14, '1000000014', 4, 12, 105.00, 'ECONOMY',  '6C'),
 (15, '1000000015', 8,  2, 102.00, 'ECONOMY',  '10D');
SET IDENTITY_INSERT Commercial.Ticket OFF;

SET IDENTITY_INSERT Commercial.Luggage ON;
INSERT INTO Commercial.Luggage (LuggageID, TicketID, WeightKg)
VALUES
 (1, 1, 23.00), (2, 2, 18.50), (3, 3, 31.00), (4, 3, 12.00),
 (5, 4,  9.50), (6, 9, 24.00), (7, 9, 21.50), (8, 10, 17.00),
 (9, 11, 28.00), (10, 12, 14.00), (11, 14, 19.50), (12, 15, 22.00);
SET IDENTITY_INSERT Commercial.Luggage OFF;

/* -------------------------------- SECURITY ------------------------------- */
SET IDENTITY_INSERT Security.BanList ON;
INSERT INTO Security.BanList
    (BanID, PassengerID, AddedByEmployeeID, ActiveFrom, ActiveTo, Reason)
VALUES
 (1, 6, 2, DATEADD(day, -10, @today), DATEADD(day, 80, @today),
     N'Security alert received from the national authority; pending review.'),
 (2, 4, 2, DATEADD(day, -200, @today), DATEADD(day, -20, @today),
     N'Expired test entry kept for audit purposes.');
SET IDENTITY_INSERT Security.BanList OFF;

/* --------------------------- SECURITY SUPPORT ---------------------------- */
INSERT INTO Security.UserAccount (LoginName, PassengerID, EmployeeID, ActorType)
VALUES
 ('demo_passenger',   1,    NULL, 'PASSENGER'),
 ('demo_checkin',     NULL, 1,    'CHECK_IN_AGENT'),
 ('demo_coordinator', NULL, 4,    'FLIGHT_COORDINATOR'),
 ('demo_security',    NULL, 2,    'SECURITY_OFFICER'),
 ('demo_hr',          NULL, 3,    'HR_MANAGER'),
 ('demo_dba',         NULL, NULL, 'DBA');

INSERT INTO Security.AgentFlightAssignment (LoginName, FlightID)
VALUES ('demo_checkin', 1), ('demo_checkin', 2), ('demo_checkin', 3);
GO

PRINT 'Sample data loaded.';
GO

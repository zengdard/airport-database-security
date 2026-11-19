/* ============================================================================
   01_schema.sql : the 19 entities of the conceptual model.
   Naming rule: Entity -> <Group schema>.<Entity name>, e.g. Flight ->
   Operational.Flight. Every primary key is a surrogate INT IDENTITY, every
   relationship is non-identifying (the FK is never part of the PK).
   ============================================================================ */
USE AirportDB;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ============================== PERSONAL ================================= */

CREATE TABLE Personal.Person
(
    PersonID            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Person PRIMARY KEY,
    FirstName           NVARCHAR(50)  NOT NULL,
    MiddleName          NVARCHAR(50)  NULL,
    LastName            NVARCHAR(50)  NOT NULL,
    DateOfBirth         DATE          NOT NULL,
    PlaceOfBirth        NVARCHAR(100) NULL,
    Sex                 CHAR(1)       NOT NULL
        CONSTRAINT CK_Person_Sex CHECK (Sex IN ('F','M','X')),
    PhoneNumber         VARCHAR(30)   NULL,
    Email               NVARCHAR(254) NULL,
    ResidentialAddress  NVARCHAR(255) NULL,
    CreatedAt           DATETIME2(0)  NOT NULL CONSTRAINT DF_Person_CreatedAt DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Personal.Passport
(
    PassportID       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Passport PRIMARY KEY,
    PersonID         INT           NOT NULL,
    DocumentType     VARCHAR(20)   NOT NULL
        CONSTRAINT CK_Passport_Type CHECK (DocumentType IN ('PASSPORT','ID_CARD','RESIDENCE_PERMIT')),
    DocumentNumber   VARCHAR(40)   NOT NULL,
    IssuingCountry   CHAR(2)       NOT NULL,
    Nationality      CHAR(2)       NOT NULL,
    IssueDate        DATE          NOT NULL,
    ExpiryDate       DATE          NOT NULL,
    CONSTRAINT CK_Passport_Dates CHECK (ExpiryDate > IssueDate),
    CONSTRAINT FK_Passport_Person FOREIGN KEY (PersonID)
        REFERENCES Personal.Person (PersonID),
    CONSTRAINT UQ_Passport_Document UNIQUE (DocumentType, DocumentNumber, IssuingCountry)
);
GO

/* ============================= OPERATIONAL =============================== */

CREATE TABLE Operational.Airport
(
    AirportID     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Airport PRIMARY KEY,
    IATACode      CHAR(3)       NOT NULL CONSTRAINT UQ_Airport_Code UNIQUE,
    Name          NVARCHAR(100) NOT NULL,
    Country       NVARCHAR(60)  NOT NULL,
    City          NVARCHAR(60)  NOT NULL,
    TimeZone      NVARCHAR(50)  NOT NULL,
    ContactPhone  VARCHAR(30)   NULL,
    Address       NVARCHAR(255) NULL
);
GO

CREATE TABLE Operational.Route
(
    RouteID            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Route PRIMARY KEY,
    OriginAirportID    INT NOT NULL,
    DestinationAirportID INT NOT NULL,
    ExpectedDurationMinutes SMALLINT NOT NULL
        CONSTRAINT CK_Route_Duration CHECK (ExpectedDurationMinutes > 0),
    CONSTRAINT CK_Route_Airports CHECK (OriginAirportID <> DestinationAirportID),
    CONSTRAINT FK_Route_Origin FOREIGN KEY (OriginAirportID)
        REFERENCES Operational.Airport (AirportID),
    CONSTRAINT FK_Route_Destination FOREIGN KEY (DestinationAirportID)
        REFERENCES Operational.Airport (AirportID)
);
GO

CREATE TABLE Operational.Plane
(
    PlaneID        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Plane PRIMARY KEY,
    Model          NVARCHAR(50) NOT NULL,
    SeatCount      SMALLINT     NOT NULL CONSTRAINT CK_Plane_Seats CHECK (SeatCount > 0),
    InServiceSince DATE         NOT NULL
);
GO

CREATE TABLE Operational.Terminal
(
    TerminalID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Terminal PRIMARY KEY,
    AirportID  INT           NOT NULL,
    Name       NVARCHAR(50)  NOT NULL,
    CONSTRAINT FK_Terminal_Airport FOREIGN KEY (AirportID)
        REFERENCES Operational.Airport (AirportID),
    CONSTRAINT UQ_Terminal_Name UNIQUE (AirportID, Name)
);
GO

CREATE TABLE Operational.Gate
(
    GateID     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Gate PRIMARY KEY,
    TerminalID INT          NOT NULL,
    GateNumber VARCHAR(10)  NOT NULL,
    CONSTRAINT FK_Gate_Terminal FOREIGN KEY (TerminalID)
        REFERENCES Operational.Terminal (TerminalID),
    CONSTRAINT UQ_Gate_Number UNIQUE (TerminalID, GateNumber)
);
GO

CREATE TABLE Operational.Flight
(
    FlightID       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Flight PRIMARY KEY,
    FlightNumber   VARCHAR(10)   NOT NULL,
    DepartureTime  DATETIME2(0)  NOT NULL,
    Status         VARCHAR(20)   NOT NULL
        CONSTRAINT DF_Flight_Status DEFAULT 'SCHEDULED'
        CONSTRAINT CK_Flight_Status CHECK (Status IN ('SCHEDULED','BOARDING','DEPARTED','DELAYED','CANCELLED')),
    DelayMinutes   SMALLINT      NOT NULL CONSTRAINT DF_Flight_Delay DEFAULT 0
        CONSTRAINT CK_Flight_Delay CHECK (DelayMinutes >= 0),
    PlaneID        INT           NOT NULL,
    RouteID        INT           NOT NULL,
    GateID         INT           NULL,
    CONSTRAINT FK_Flight_Plane FOREIGN KEY (PlaneID)
        REFERENCES Operational.Plane (PlaneID),
    CONSTRAINT FK_Flight_Route FOREIGN KEY (RouteID)
        REFERENCES Operational.Route (RouteID),
    CONSTRAINT FK_Flight_Gate FOREIGN KEY (GateID)
        REFERENCES Operational.Gate (GateID),
    CONSTRAINT UQ_Flight_Number UNIQUE (FlightNumber, DepartureTime)
);
GO

/* ============================== WORKFORCE ================================ */

CREATE TABLE Workforce.Department
(
    DepartmentID   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Department PRIMARY KEY,
    TerminalID     INT           NOT NULL,
    DepartmentType VARCHAR(40)   NOT NULL,
    Name           NVARCHAR(80)  NOT NULL,
    CONSTRAINT FK_Department_Terminal FOREIGN KEY (TerminalID)
        REFERENCES Operational.Terminal (TerminalID)
);
GO

CREATE TABLE Workforce.Employee
(
    EmployeeID   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Employee PRIMARY KEY,
    PersonID     INT           NOT NULL,
    HireDate     DATE          NOT NULL,
    Position     NVARCHAR(50)  NOT NULL,
    Salary       DECIMAL(12,2) NOT NULL CONSTRAINT CK_Employee_Salary CHECK (Salary >= 0),
    WorkSchedule NVARCHAR(100) NULL,
    CONSTRAINT FK_Employee_Person FOREIGN KEY (PersonID)
        REFERENCES Personal.Person (PersonID),
    CONSTRAINT UQ_Employee_Person UNIQUE (PersonID)
);
GO

CREATE TABLE Workforce.GroundEmployee
(
    EmployeeID   INT NOT NULL CONSTRAINT PK_GroundEmployee PRIMARY KEY,
    DepartmentID INT NOT NULL,
    CONSTRAINT FK_GroundEmployee_Employee FOREIGN KEY (EmployeeID)
        REFERENCES Workforce.Employee (EmployeeID),
    CONSTRAINT FK_GroundEmployee_Department FOREIGN KEY (DepartmentID)
        REFERENCES Workforce.Department (DepartmentID)
);
GO

CREATE TABLE Workforce.AirEmployee
(
    EmployeeID  INT NOT NULL CONSTRAINT PK_AirEmployee PRIMARY KEY,
    FlightHours INT NOT NULL CONSTRAINT DF_AirEmployee_Hours DEFAULT 0
        CONSTRAINT CK_AirEmployee_Hours CHECK (FlightHours >= 0),
    CONSTRAINT FK_AirEmployee_Employee FOREIGN KEY (EmployeeID)
        REFERENCES Workforce.Employee (EmployeeID)
);
GO

CREATE TABLE Workforce.License
(
    LicenseID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_License PRIMARY KEY,
    Name      NVARCHAR(80) NOT NULL,
    Category  VARCHAR(40)  NOT NULL
);
GO

CREATE TABLE Workforce.EmployeeLicense
(
    EmployeeLicenseID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_EmployeeLicense PRIMARY KEY,
    EmployeeID        INT  NOT NULL,
    LicenseID         INT  NOT NULL,
    IssueDate         DATE NOT NULL,
    ExpiryDate        DATE NOT NULL,
    CONSTRAINT CK_EmployeeLicense_Dates CHECK (ExpiryDate > IssueDate),
    CONSTRAINT FK_EmployeeLicense_Employee FOREIGN KEY (EmployeeID)
        REFERENCES Workforce.Employee (EmployeeID),
    CONSTRAINT FK_EmployeeLicense_License FOREIGN KEY (LicenseID)
        REFERENCES Workforce.License (LicenseID),
    CONSTRAINT UQ_EmployeeLicense UNIQUE (EmployeeID, LicenseID, IssueDate)
);
GO

CREATE TABLE Operational.CrewMember
(
    CrewMemberID  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CrewMember PRIMARY KEY,
    FlightID      INT          NOT NULL,
    AirEmployeeID INT          NOT NULL,
    CrewRole      VARCHAR(30)  NOT NULL
        CONSTRAINT CK_Crew_Role CHECK (CrewRole IN ('CAPTAIN','FIRST_OFFICER','PURSER','CABIN_CREW')),
    CONSTRAINT FK_CrewMember_Flight FOREIGN KEY (FlightID)
        REFERENCES Operational.Flight (FlightID),
    CONSTRAINT FK_CrewMember_AirEmployee FOREIGN KEY (AirEmployeeID)
        REFERENCES Workforce.AirEmployee (EmployeeID),
    CONSTRAINT UQ_CrewMember UNIQUE (FlightID, AirEmployeeID)
);
GO

/* ============================== COMMERCIAL =============================== */

CREATE TABLE Commercial.Passenger
(
    PassengerID         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Passenger PRIMARY KEY,
    PersonID            INT          NOT NULL,
    FrequentFlyerNumber VARCHAR(20)  NULL,
    MilesBalance        INT          NOT NULL CONSTRAINT DF_Passenger_Miles DEFAULT 0
        CONSTRAINT CK_Passenger_Miles CHECK (MilesBalance >= 0),
    SpecialAssistance   NVARCHAR(200) NULL,
    CONSTRAINT FK_Passenger_Person FOREIGN KEY (PersonID)
        REFERENCES Personal.Person (PersonID),
    CONSTRAINT UQ_Passenger_Person UNIQUE (PersonID)
);
GO

CREATE TABLE Commercial.Ticket
(
    TicketID     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Ticket PRIMARY KEY,
    TicketNumber VARCHAR(20)   NOT NULL CONSTRAINT UQ_Ticket_Number UNIQUE,
    PassengerID  INT           NOT NULL,
    FlightID     INT           NOT NULL,
    Price        DECIMAL(10,2) NOT NULL CONSTRAINT CK_Ticket_Price CHECK (Price >= 0),
    Class        VARCHAR(10)   NOT NULL
        CONSTRAINT CK_Ticket_Class CHECK (Class IN ('ECONOMY','PREMIUM','BUSINESS','FIRST')),
    SeatNumber   VARCHAR(5)    NULL,
    CONSTRAINT FK_Ticket_Passenger FOREIGN KEY (PassengerID)
        REFERENCES Commercial.Passenger (PassengerID),
    CONSTRAINT FK_Ticket_Flight FOREIGN KEY (FlightID)
        REFERENCES Operational.Flight (FlightID),
    /* seat uniqueness is enforced by a filtered index (NULL = not assigned yet) */
);
GO

CREATE TABLE Commercial.Luggage
(
    LuggageID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Luggage PRIMARY KEY,
    TicketID  INT           NOT NULL,
    WeightKg  DECIMAL(5,2)  NOT NULL CONSTRAINT CK_Luggage_Weight CHECK (WeightKg > 0),
    CONSTRAINT FK_Luggage_Ticket FOREIGN KEY (TicketID)
        REFERENCES Commercial.Ticket (TicketID) ON DELETE CASCADE
);
GO

/* =============================== SECURITY ================================ */

CREATE TABLE Security.BanList
(
    BanID               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BanList PRIMARY KEY,
    PassengerID         INT           NOT NULL,
    AddedByEmployeeID   INT           NOT NULL,
    ActiveFrom          DATE          NOT NULL,
    ActiveTo            DATE          NOT NULL,
    Reason              NVARCHAR(500) NOT NULL,
    CONSTRAINT CK_BanList_Period CHECK (ActiveTo > ActiveFrom),
    CONSTRAINT FK_BanList_Passenger FOREIGN KEY (PassengerID)
        REFERENCES Commercial.Passenger (PassengerID),
    CONSTRAINT FK_BanList_Employee FOREIGN KEY (AddedByEmployeeID)
        REFERENCES Workforce.Employee (EmployeeID)
);
GO

/* ============================================================================
   Technical tables (not part of the 19-entity conceptual model).
   They carry the information needed by the application-level security rules.
   ============================================================================ */

CREATE TABLE Security.UserAccount
(
    LoginName  SYSNAME      NOT NULL CONSTRAINT PK_UserAccount PRIMARY KEY,
    PassengerID INT         NULL,
    EmployeeID  INT         NULL,
    ActorType   VARCHAR(30) NOT NULL,
    CONSTRAINT FK_UserAccount_Passenger FOREIGN KEY (PassengerID)
        REFERENCES Commercial.Passenger (PassengerID),
    CONSTRAINT FK_UserAccount_Employee FOREIGN KEY (EmployeeID)
        REFERENCES Workforce.Employee (EmployeeID),
    CONSTRAINT CK_UserAccount_OnePerson CHECK
        ((PassengerID IS NOT NULL AND EmployeeID IS NULL)
      OR (PassengerID IS NULL AND EmployeeID IS NOT NULL)
      OR (PassengerID IS NULL AND EmployeeID IS NULL))   -- DBA account
);
GO

CREATE TABLE Security.AgentFlightAssignment
(
    LoginName SYSNAME NOT NULL,
    FlightID  INT     NOT NULL,
    CONSTRAINT PK_AgentFlightAssignment PRIMARY KEY (LoginName, FlightID),
    CONSTRAINT FK_AgentFlightAssignment_Flight FOREIGN KEY (FlightID)
        REFERENCES Operational.Flight (FlightID)
);
GO

CREATE TABLE Security.AuditLog
(
    AuditLogID  BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLog PRIMARY KEY,
    OccurredAt  DATETIME2(3) NOT NULL CONSTRAINT DF_AuditLog_Date DEFAULT SYSUTCDATETIME(),
    LoginName   SYSNAME      NOT NULL CONSTRAINT DF_AuditLog_Login DEFAULT ORIGINAL_LOGIN(),
    Action      VARCHAR(10)  NOT NULL,
    ObjectName  NVARCHAR(128) NOT NULL,
    Details     NVARCHAR(400) NULL
);
GO

/* =============================== INDEXES ================================= */

CREATE INDEX IX_Passport_Person          ON Personal.Passport (PersonID);
CREATE INDEX IX_Route_Origin             ON Operational.Route (OriginAirportID);
CREATE INDEX IX_Route_Destination        ON Operational.Route (DestinationAirportID);
CREATE INDEX IX_Terminal_Airport         ON Operational.Terminal (AirportID);
CREATE INDEX IX_Flight_Departure         ON Operational.Flight (DepartureTime);
CREATE INDEX IX_Flight_Plane             ON Operational.Flight (PlaneID);
CREATE INDEX IX_Flight_Route             ON Operational.Flight (RouteID);
CREATE INDEX IX_Flight_Gate              ON Operational.Flight (GateID);
CREATE INDEX IX_CrewMember_Flight        ON Operational.CrewMember (FlightID);
CREATE INDEX IX_CrewMember_AirEmployee   ON Operational.CrewMember (AirEmployeeID);
CREATE INDEX IX_Employee_Person          ON Workforce.Employee (PersonID);
CREATE INDEX IX_GroundEmployee_Dept      ON Workforce.GroundEmployee (DepartmentID);
CREATE INDEX IX_EmployeeLicense_Employee ON Workforce.EmployeeLicense (EmployeeID);
CREATE INDEX IX_EmployeeLicense_License  ON Workforce.EmployeeLicense (LicenseID);
CREATE UNIQUE INDEX UQ_Passenger_FF
    ON Commercial.Passenger (FrequentFlyerNumber)
    WHERE FrequentFlyerNumber IS NOT NULL;
CREATE UNIQUE INDEX UQ_Ticket_Seat
    ON Commercial.Ticket (FlightID, SeatNumber)
    WHERE SeatNumber IS NOT NULL;
CREATE INDEX IX_Ticket_Passenger         ON Commercial.Ticket (PassengerID);
CREATE INDEX IX_Ticket_Flight            ON Commercial.Ticket (FlightID);
CREATE INDEX IX_Luggage_Ticket           ON Commercial.Luggage (TicketID);
CREATE INDEX IX_BanList_Passenger        ON Security.BanList (PassengerID);
CREATE INDEX IX_AuditLog_OccurredAt      ON Security.AuditLog (OccurredAt);
GO

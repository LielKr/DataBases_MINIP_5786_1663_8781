-- =========================================
--           RESERVATIONS MODULE
-- =========================================

-- Table: Guest
-- Stores all guest personal information
CREATE TABLE Guest (
    GuestID SERIAL PRIMARY KEY,           -- Unique ID for each guest
    FirstName VARCHAR(50),                -- Guest first name
    LastName VARCHAR(50),                 -- Guest last name
    Email VARCHAR(100) UNIQUE,            -- Unique email per guest
    Phone VARCHAR(20),                    -- Phone number
    PassportNumber VARCHAR(50)            -- Identification / passport
);

COMMENT ON TABLE Guest IS 'Stores guest personal details';
COMMENT ON COLUMN Guest.GuestID IS 'Primary key of guest';


-- Table: ReservationStatus
-- Defines possible reservation states (Booked, Cancelled, Completed, etc.)
CREATE TABLE ReservationStatus (
    StatusID SERIAL PRIMARY KEY,
    StatusName VARCHAR(50) UNIQUE         -- Name of status
);

-- Table: ReservationSource
-- Defines where reservation came from (Website, Booking, Walk-in)
CREATE TABLE ReservationSource (
    SourceID SERIAL PRIMARY KEY,
    SourceName VARCHAR(50)
);


-- Table: Reservation
-- Core reservation entity
CREATE TABLE Reservation (
    ReservationID SERIAL PRIMARY KEY,
    GuestID INT,                          -- FK to Guest
    StatusID INT,                         -- FK to ReservationStatus
    SourceID INT,                         -- FK to ReservationSource
    ReservationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CheckInDate DATE,
    CheckOutDate DATE,

    FOREIGN KEY (GuestID) REFERENCES Guest(GuestID),
    FOREIGN KEY (StatusID) REFERENCES ReservationStatus(StatusID),
    FOREIGN KEY (SourceID) REFERENCES ReservationSource(SourceID)
);

COMMENT ON TABLE Reservation IS 'Main reservation table';


-- Table: Room
-- Basic room information (minimal for linking)
CREATE TABLE Room (
    RoomID SERIAL PRIMARY KEY,
    RoomNumber INT UNIQUE,
    Floor INT
);


-- Table: ReservationRoom
-- Resolves many-to-many relationship between Reservation and Room
CREATE TABLE ReservationRoom (
    ReservationRoomID SERIAL PRIMARY KEY,
    ReservationID INT,
    RoomID INT,

    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    FOREIGN KEY (RoomID) REFERENCES Room(RoomID)
);

COMMENT ON TABLE ReservationRoom IS 'Links reservations to rooms';


-- Table: ReservationHistory
-- Tracks status changes over time
CREATE TABLE ReservationHistory (
    HistoryID SERIAL PRIMARY KEY,
    ReservationID INT,
    StatusID INT,
    ChangeDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    FOREIGN KEY (StatusID) REFERENCES ReservationStatus(StatusID)
);

COMMENT ON TABLE ReservationHistory IS 'Tracks reservation status changes';


-- =========================================
--           FRONT DESK MODULE
-- =========================================

-- Table: Employee
-- Stores hotel staff information
CREATE TABLE Employee (
    EmployeeID SERIAL PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Role VARCHAR(50)                     -- Receptionist, Manager, etc.
);

COMMENT ON TABLE Employee IS 'Stores employee data';


-- Table: CheckIn
-- Represents actual guest arrival
CREATE TABLE CheckIn (
    CheckInID SERIAL PRIMARY KEY,
    ReservationID INT UNIQUE,            -- One reservation → one check-in
    EmployeeID INT,                      -- Employee who handled check-in
    CheckInDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

COMMENT ON TABLE CheckIn IS 'Stores check-in records';


-- Table: CheckOut
-- Represents guest departure
CREATE TABLE CheckOut (
    CheckOutID SERIAL PRIMARY KEY,
    CheckInID INT UNIQUE,                -- One check-in → one checkout
    CheckOutDate TIMESTAMP,
    PaymentStatus VARCHAR(50),           -- Paid / Pending

    FOREIGN KEY (CheckInID) REFERENCES CheckIn(CheckInID)
);

COMMENT ON TABLE CheckOut IS 'Stores check-out records';


-- Table: RoomAssignment
-- Actual room given during check-in (can differ from reservation)
CREATE TABLE RoomAssignment (
    AssignmentID SERIAL PRIMARY KEY,
    CheckInID INT,
    RoomID INT,
    AssignedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (CheckInID) REFERENCES CheckIn(CheckInID),
    FOREIGN KEY (RoomID) REFERENCES Room(RoomID)
);

COMMENT ON TABLE RoomAssignment IS 'Tracks assigned rooms during stay';


-- Table: EarlyCheckIn
-- Handles early check-in approvals and fees
CREATE TABLE EarlyCheckIn (
    EarlyCheckInID SERIAL PRIMARY KEY,
    CheckInID INT,
    Approved BOOLEAN DEFAULT FALSE,
    ExtraFee DECIMAL(10,2),

    FOREIGN KEY (CheckInID) REFERENCES CheckIn(CheckInID)
);

COMMENT ON TABLE EarlyCheckIn IS 'Stores early check-in requests';


-- Table: LateCheckOut
-- Handles late check-out approvals and fees
CREATE TABLE LateCheckOut (
    LateCheckOutID SERIAL PRIMARY KEY,
    CheckOutID INT,
    Approved BOOLEAN DEFAULT FALSE,
    ExtraFee DECIMAL(10,2),

    FOREIGN KEY (CheckOutID) REFERENCES CheckOut(CheckOutID)
);

COMMENT ON TABLE LateCheckOut IS 'Stores late check-out requests';


-- Table: FrontDeskLog
-- Logs actions performed by employees
CREATE TABLE FrontDeskLog (
    LogID SERIAL PRIMARY KEY,
    EmployeeID INT,
    ActionDescription TEXT,              -- Description of action
    ActionTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

COMMENT ON TABLE FrontDeskLog IS 'Tracks front desk activities';


-- =========================================
--           RESERVATIONS MODULE
-- =========================================

-- Insert sample guests
INSERT INTO Guest (FirstName, LastName, Email, Phone, PassportNumber)
VALUES
('John', 'Doe', 'john.doe@gmail.com', '1234567890', 'G123456'),
('Jane', 'Smith', 'jane.smith@yahoo.com', '0987654321', 'G654321'),
('Mike', 'Johnson', 'mike.johnson@outlook.com', '1122334455', 'G234567'),
('Sarah', 'Williams', 'sarah.williams@hotmail.com', '2233445566', 'G345678'),
('David', 'Brown', 'david.brown92@gmail.com', '3344556677', 'G456789'),
('Emily', 'Jones', 'emily.jones@icloud.com', '4455667788', 'G567890'),
('Chris', 'Garcia', 'chrisgarcia77@outlook.com', '5566778899', 'G678901'),
('Lisa', 'Miller', 'lisa.miller@yahoo.com', '6677889900', 'G789012'),
('James', 'Davis', 'jdavis85@gmail.com', '7788990011', 'G890123'),
('Mary', 'Rodriguez', 'mary.rodriguez@hotmail.com', '8899001122', 'G901234');

-- Insert reservation statuses
INSERT INTO ReservationStatus (StatusName)
VALUES
('Booked'),
('Cancelled'),
('Completed'),
('No Show'),
('Checked In');

-- Insert reservation sources
INSERT INTO ReservationSource (SourceName)
VALUES
('Website'),
('Booking.com'),
('Expedia'),
('Walk-in'),
('Phone');

-- Insert sample reservations
INSERT INTO Reservation (GuestID, StatusID, SourceID, CheckInDate, CheckOutDate)
VALUES
(1, 1, 1, '2024-06-01', '2024-06-05'),
(2, 1, 2, '2024-06-02', '2024-06-04'),
(3, 1, 3, '2024-06-03', '2024-06-06'),
(4, 1, 1, '2024-06-04', '2024-06-07'),
(5, 1, 4, '2024-06-05', '2024-06-08'),
(6, 1, 5, '2024-06-06', '2024-06-09'),
(7, 1, 1, '2024-06-07', '2024-06-10'),
(8, 1, 2, '2024-06-08', '2024-06-11'),
(9, 1, 3, '2024-06-09', '2024-06-12'),
(10, 1, 4, '2024-06-10', '2024-06-13');

-- Insert sample rooms
INSERT INTO Room (RoomNumber, Floor)
VALUES
(101, 1),
(102, 1),
(103, 1),
(201, 2),
(202, 2),
(203, 2),
(301, 3),
(302, 3),
(303, 3),
(401, 4);

-- Insert sample reservation-room links
INSERT INTO ReservationRoom (ReservationID, RoomID)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

-- Insert sample reservation histories
INSERT INTO ReservationHistory (ReservationID, StatusID)
VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 1),
(5, 1),
(6, 1),
(7, 1),
(8, 1),
(9, 1),
(10, 1);


-- =========================================
--           FRONT DESK MODULE
-- =========================================

-- Insert sample employees
INSERT INTO Employee (FirstName, LastName, Role)
VALUES
('Alice', 'Smith', 'Receptionist'),
('Bob', 'Johnson', 'Receptionist'),
('Charlie', 'Williams', 'Manager'),
('Diana', 'Brown', 'Receptionist'),
('Ethan', 'Jones', 'Manager'),
('Fiona', 'Garcia', 'Receptionist'),
('George', 'Miller', 'Receptionist'),
('Hannah', 'Davis', 'Manager'),
('Ian', 'Rodriguez', 'Receptionist'),
('Julia', 'Martinez', 'Manager');

-- Insert sample check-ins
INSERT INTO CheckIn (ReservationID, EmployeeID, CheckInDate)
VALUES
(1, 1, '2024-06-01 14:30:00'),
(2, 2, '2024-06-02 15:00:00'),
(3, 3, '2024-06-03 14:45:00'),
(4, 4, '2024-06-04 15:15:00'),
(5, 5, '2024-06-05 14:20:00'),
(6, 6, '2024-06-06 15:30:00'),
(7, 7, '2024-06-07 14:40:00'),
(8, 8, '2024-06-08 15:10:00'),
(9, 9, '2024-06-09 14:50:00'),
(10, 10, '2024-06-10 15:20:00');

-- Insert sample check-outs
INSERT INTO CheckOut (CheckInID, CheckOutDate, PaymentStatus)
VALUES
(1, '2024-06-05 11:00:00', 'Paid'),
(2, '2024-06-04 10:30:00', 'Paid'),
(3, '2024-06-06 11:30:00', 'Paid'),
(4, '2024-06-07 10:45:00', 'Paid'),
(5, '2024-06-08 11:15:00', 'Paid'),
(6, '2024-06-09 10:15:00', 'Paid'),
(7, '2024-06-10 11:45:00', 'Paid'),
(8, '2024-06-11 10:30:00', 'Paid'),
(9, '2024-06-12 11:15:00', 'Paid'),
(10, '2024-06-13 10:45:00', 'Paid');

-- Insert sample room assignments
INSERT INTO RoomAssignment (CheckInID, RoomID, AssignedDate)
VALUES
(1, 1, '2024-06-01 14:30:00'),
(2, 2, '2024-06-02 15:00:00'),
(3, 3, '2024-06-03 14:45:00'),
(4, 4, '2024-06-04 15:15:00'),
(5, 5, '2024-06-05 14:20:00'),
(6, 6, '2024-06-06 15:30:00'),
(7, 7, '2024-06-07 14:40:00'),
(8, 8, '2024-06-08 15:10:00'),
(9, 9, '2024-06-09 14:50:00'),
(10, 10, '2024-06-10 15:20:00');

-- Insert sample early check-ins
INSERT INTO EarlyCheckIn (CheckInID, Approved, ExtraFee)
VALUES
(1, TRUE, 25.00),
(3, TRUE, 20.00),
(5, FALSE, 0.00),
(7, TRUE, 30.00),
(9, FALSE, 0.00);

-- Insert sample late check-outs
INSERT INTO LateCheckOut (CheckOutID, Approved, ExtraFee)
VALUES
(1, TRUE, 50.00),
(3, TRUE, 40.00),
(5, FALSE, 0.00),
(7, TRUE, 60.00),
(9, FALSE, 0.00);

-- Insert sample front desk logs
INSERT INTO FrontDeskLog (EmployeeID, ActionDescription)
VALUES
(1, 'Checked in guest John Doe'),
(2, 'Checked in guest Jane Smith'),
(3, 'Checked in guest Mike Johnson'),
(4, 'Checked in guest Sarah Williams'),
(5, 'Checked in guest David Brown'),
(6, 'Checked in guest Emily Jones'),
(7, 'Checked in guest Chris Garcia'),
(8, 'Checked in guest Lisa Miller'),
(9, 'Checked in guest James Davis'),
(10, 'Checked in guest Mary Rodriguez'),
(1, 'Processed check-out for John Doe'),
(2, 'Processed check-out for Jane Smith'),
(3, 'Processed check-out for Mike Johnson'),
(4, 'Processed check-out for Sarah Williams'),
(5, 'Processed check-out for David Brown'),
(6, 'Processed check-out for Emily Jones'),
(7, 'Processed check-out for Chris Garcia'),
(8, 'Processed check-out for Lisa Miller'),
(9, 'Processed check-out for James Davis'),
(10, 'Processed check-out for Mary Rodriguez');       
               
commit;
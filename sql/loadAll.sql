-- -----------------------
-- USERS
-- -----------------------
INSERT INTO users (user_id, role, name, email, status) VALUES
(1, 'student', 'Alice Johnson', 'alice1@umbc.edu', 'active'),
(2, 'student', 'Brian Smith', 'brian2@umbc.edu', 'active'),
(3, 'faculty_staff', 'Dr Green', 'green@umbc.edu', 'active'),
(4, 'faculty_staff', 'Lisa Brown', 'lbrown@umbc.edu', 'active'),
(5, 'visitor', 'Tom White', 'tomwhite@gmail.com', 'active'),
(6, 'visitor', 'Sarah Lee', 'sarahlee@gmail.com', 'active'),
(7, 'admin', 'Karen Admin', 'kadmin@umbc.edu', 'active'),
(8, 'officer', 'Mike Officer', 'mofficer@umbc.edu', 'active'),
(9, 'student', 'Daniel Hall', 'dhall@umbc.edu', 'inactive'),
(10, 'student', 'Eva King', 'eking@umbc.edu', 'suspended');



INSERT INTO permit_type (permit_type_id, name, user_category, max_vehicles, price) VALUES
(1, 'Student Commuter', 'student', 1, 250.00),
(2, 'Student Resident', 'student', 1, 300.00),
(3, 'Faculty Full Time', 'faculty_staff', 2, 400.00),
(4, 'Faculty Part Time', 'faculty_staff', 1, 200.00),
(5, 'Visitor Day Pass', 'visitor', 1, 15.00),
(6, 'Visitor Week Pass', 'visitor', 1, 50.00),
(7, 'Evening Student', 'student', 1, 100.00),
(8, 'Staff Reserved', 'faculty_staff', 2, 450.00),
(9, 'Summer Student', 'student', 1, 80.00),
(10, 'Conference Visitor', 'visitor', 1, 25.00);



INSERT INTO lots (lot_id, name, zone_code, location_desc, visitor_allowed) VALUES
(1, 'Lot A', 'A', 'Near library', FALSE),
(2, 'Lot B', 'B', 'Near engineering building', FALSE),
(3, 'Lot C', 'C', 'Near dorms', FALSE),
(4, 'Lot D', 'D', 'Near admin building', TRUE),
(5, 'Lot E', 'E', 'Near gym', TRUE),
(6, 'Lot F', 'F', 'South campus', FALSE),
(7, 'Lot G', 'G', 'North campus', FALSE),
(8, 'Lot H', 'H', 'Event parking', TRUE),
(9, 'Lot I', 'I', 'Visitor overflow', TRUE),
(10, 'Lot J', 'J', 'Research center', FALSE);



INSERT INTO vehicles (vehicle_id, user_id, plate_no, plate_state, vehicle_type) VALUES
(1, 1, 'ABC101', 'MD', 'sedan'),
(2, 2, 'ABC102', 'MD', 'suv'),
(3, 3, 'FAC201', 'MD', 'sedan'),
(4, 4, 'FAC202', 'VA', 'truck'),
(5, 5, 'VIS301', 'MD', 'van'),
(6, 6, 'VIS302', 'DC', 'sedan'),
(7, 1, 'ABC103', 'MD', 'motorcycle'),
(8, 9, 'STU401', 'VA', 'sedan'),
(9, 10, 'STU402', 'MD', 'suv'),
(10, 3, 'FAC203', 'MD', 'other');



INSERT INTO permits (permit_id, user_id, permit_type_id, status, start_date, end_date) VALUES
(1, 1, 1, 'active', '2026-01-10', '2026-12-20'),
(2, 2, 2, 'active', '2026-01-10', '2026-12-20'),
(3, 3, 3, 'active', '2026-01-01', '2026-12-31'),
(4, 4, 4, 'active', '2026-01-01', '2026-08-31'),
(5, 5, 5, 'expired', '2026-03-01', '2026-03-01'),
(6, 6, 6, 'active', '2026-04-01', '2026-04-07'),
(7, 1, 7, 'cancelled', '2026-02-01', '2026-05-01'),
(8, 3, 8, 'active', '2026-01-01', '2026-12-31'),
(9, 9, 9, 'expired', '2025-06-01', '2025-08-15'),
(10, 5, 10, 'pending', '2026-04-10', '2026-04-12');



INSERT INTO spots (spot_id, lot_id, spot_number, spot_type, status, is_reservable) VALUES
(1, 1, 'A1', 'student', 'available', TRUE),
(2, 1, 'A2', 'student', 'available', TRUE),
(3, 2, 'B1', 'faculty_staff', 'available', TRUE),
(4, 2, 'B2', 'faculty_staff', 'occupied', FALSE),
(5, 4, 'D1', 'visitor', 'available', TRUE),
(6, 4, 'D2', 'visitor', 'available', TRUE),
(7, 5, 'E1', 'general', 'available', TRUE),
(8, 6, 'F1', 'accessible', 'maintenance', FALSE),
(9, 8, 'H1', 'ev', 'available', TRUE),
(10, 9, 'I1', 'visitor', 'available', TRUE);


INSERT INTO permit_vehicle (permit_id, vehicle_id, linked_at) VALUES
(1, 1, '2026-01-10 09:00:00'),
(2, 2, '2026-01-10 09:15:00'),
(3, 3, '2026-01-05 08:00:00'),
(4, 4, '2026-01-06 08:10:00'),
(5, 5, '2026-03-01 07:00:00'),
(6, 6, '2026-04-01 08:30:00'),
(1, 7, '2026-01-11 10:00:00'),
(9, 8, '2025-06-01 12:00:00'),
(7, 9, '2026-02-03 01:00:00'),
(8, 10, '2026-01-03 08:45:00');



INSERT INTO reservations (reservation_id, user_id, spot_id, vehicle_id, start_ts, end_ts, status) VALUES
(1, 1, 1, 1, '2026-04-05 08:00:00', '2026-04-05 12:00:00', 'confirmed'),
(2, 2, 2, 2, '2026-04-05 09:00:00', '2026-04-05 11:00:00', 'confirmed'),
(3, 3, 3, 3, '2026-04-05 07:30:00', '2026-04-05 10:30:00', 'confirmed'),
(4, 4, 4, 4, '2026-04-05 08:00:00', '2026-04-05 09:00:00', 'cancelled'),
(5, 5, 5, 5, '2026-04-06 10:00:00', '2026-04-06 14:00:00', 'confirmed'),
(6, 6, 6, 6, '2026-04-06 11:00:00', '2026-04-06 13:00:00', 'pending'),
(7, 1, 7, 7, '2026-04-07 13:00:00', '2026-04-07 15:00:00', 'completed'),
(8, 9, 8, 8, '2026-04-08 09:00:00', '2026-04-08 11:00:00', 'cancelled'),
(9, 10, 9, 9, '2026-04-08 14:00:00', '2026-04-08 16:00:00', 'pending'),
(10, 3, 10, 10, '2026-04-09 08:30:00', '2026-04-09 10:30:00', 'confirmed');


INSERT INTO tickets (ticket_id, vehicle_id, spot_id, issued_at, violation_code, amount, status) VALUES
(1, 1, 1, '2026-03-15 09:20:00', 'NO_PERMIT', 50.00, 'unpaid'),
(2, 2, 2, '2026-03-16 10:00:00', 'EXPIRED_PERMIT', 35.00, 'paid'),
(3, 3, 3, '2026-03-17 11:15:00', 'ILLEGAL_ZONE', 75.00, 'partial'),
(4, 4, 4, '2026-03-18 12:30:00', 'NO_PAYMENT', 40.00, 'unpaid'),
(5, 5, 5, '2026-03-19 01:00:00', 'VISITOR_VIOLATION', 25.00, 'paid'),
(6, 6, 6, '2026-03-20 02:10:00', 'TIME_LIMIT', 20.00, 'unpaid'),
(7, 7, 7, '2026-03-21 08:45:00', 'NO_PERMIT', 50.00, 'partial'),
(8, 8, 8, '2026-03-22 03:20:00', 'MAINTENANCE_ZONE', 60.00, 'unpaid'),
(9, 9, 9, '2026-03-23 04:00:00', 'EV_ONLY', 45.00, 'paid'),
(10, 10, 10, '2026-03-24 09:10:00', 'NO_PERMIT', 50.00, 'unpaid');



INSERT INTO payments (payment_id, ticket_id, paid_at, amount, method) VALUES
(1, 2, '2026-03-16 04:00:00', 35.00, 'card'),
(2, 3, '2026-03-18 09:00:00', 25.00, 'online'),
(3, 5, '2026-03-19 05:00:00', 25.00, 'cash'),
(4, 7, '2026-03-22 08:00:00', 20.00, 'card'),
(5, 9, '2026-03-24 10:00:00', 45.00, 'online'),
(6, 3, '2026-03-25 11:00:00', 10.00, 'cash'),
(7, 1, '2026-03-26 12:00:00', 15.00, 'card'),
(8, 4, '2026-03-27 01:00:00', 10.00, 'online'),
(9, 6, '2026-03-28 02:00:00', 5.00, 'cash'),
(10, 10, '2026-03-29 03:00:00', 20.00, 'card');



SELECT
    p.permit_id,
    u.name AS user_name,
    u.role,
    pt.name AS permit_type_name,
    p.start_date,
    p.end_date
FROM permits p
JOIN users u
    ON u.user_id = p.user_id
JOIN permit_type pt
    ON pt.permit_type_id = p.permit_type_id
WHERE p.status = 'active'
  AND CURRENT_DATE BETWEEN p.start_date AND p.end_date
ORDER BY u.name;

--Query 2
--Show current lot availability using the reporting view
SELECT
    lot_name,
    total_spots,
    available_spots,
    occupied_spots,
    maintenance_spots,
    closed_spots
FROM current_lot_availability
ORDER BY lot_name;

--Query 3
--Count reservations by lot and reservation status
SELECT
    l.name AS lot_name,
    r.status,
    COUNT(*) AS reservation_count
FROM reservations r
JOIN spots s
    ON s.spot_id = r.spot_id
JOIN lots l
    ON l.lot_id = s.lot_id
GROUP BY l.name, r.status
ORDER BY l.name, r.status;

--Query 4
--Find vehicles that do not currently have an active permit
SELECT
    v.vehicle_id,
    v.plate_no,
    v.plate_state,
    u.name AS owner_name
FROM vehicles v
JOIN users u
    ON u.user_id = v.user_id
WHERE NOT EXISTS (
    SELECT 1
    FROM permit_vehicle pv
    JOIN permits p
        ON p.permit_id = pv.permit_id
    WHERE pv.vehicle_id = v.vehicle_id
      AND p.status = 'active'
      AND CURRENT_DATE BETWEEN p.start_date AND p.end_date
)
ORDER BY owner_name, v.plate_no;

--Query 5
--Show ticket balances by ticket
SELECT
    t.ticket_id,
    t.vehicle_id,
    t.violation_code,
    t.amount AS ticket_amount,
    COALESCE(SUM(p.amount), 0) AS total_paid,
    t.amount - COALESCE(SUM(p.amount), 0) AS balance_due,
    t.status
FROM tickets t
LEFT JOIN payments p
    ON p.ticket_id = t.ticket_id
GROUP BY t.ticket_id, t.vehicle_id, t.violation_code, t.amount, t.status
ORDER BY t.ticket_id;

--Query 6
--Total unpad balance by user
SELECT
    u.user_id,
    u.name,
    COUNT(t.ticket_id) AS unpaid_ticket_count,
    COALESCE(SUM(t.amount), 0) - COALESCE(SUM(pay.total_paid), 0) AS total_balance_due
FROM users u
JOIN vehicles v
    ON v.user_id = u.user_id
JOIN tickets t
    ON t.vehicle_id = v.vehicle_id
LEFT JOIN (
    SELECT
        ticket_id,
        SUM(amount) AS total_paid
    FROM payments
    GROUP BY ticket_id
) pay
    ON pay.ticket_id = t.ticket_id
WHERE t.status IN ('unpaid', 'partial')
GROUP BY u.user_id, u.name
ORDER BY total_balance_due DESC, u.name;

--Query 7
--Users with more than one vehicle
SELECT
    u.user_id,
    u.name,
    COUNT(v.vehicle_id) AS vehicle_count
FROM users u
JOIN vehicles v
    ON v.user_id = u.user_id
GROUP BY u.user_id, u.name
HAVING COUNT(v.vehicle_id) > 1
ORDER BY vehicle_count DESC, u.name;

--Query 
--Faculty users who have an active permit
SELECT
    u.user_id,
    u.name,
    pt.name AS permit_type_name
FROM users u
JOIN permits p
    ON p.user_id = u.user_id
JOIN permit_type pt
    ON pt.permit_type_id = p.permit_type_id
WHERE u.role = 'faculty_staff'
  AND p.status = 'active'
  AND CURRENT_DATE BETWEEN p.start_date AND p.end_date
ORDER BY u.name;

-- Query 9
--Find reservations conflict with a requested time window
SELECT
    r.reservation_id,
    r.user_id,
    r.spot_id,
    r.start_ts,
    r.end_ts,
    r.status
FROM reservations r
WHERE r.status IN ('pending', 'confirmed')
  AND r.start_ts < '2026-04-20 12:00:00'
  AND r.end_ts > '2026-04-20 10:00:00'
ORDER BY r.spot_id, r.start_ts;

-- Query 10
-- Latest sensor event for each spot
SELECT DISTINCT ON (se.spot_id)
    se.spot_id,
    s.spot_number,
    l.name AS lot_name,
    se.vehicle_id,
    se.event_type,
    se.event_ts
FROM sensor_events se
JOIN spots s
    ON s.spot_id = se.spot_id
JOIN lots l
    ON l.lot_id = s.lot_id
ORDER BY se.spot_id, se.event_ts DESC, se.sensor_event_id DESC;



-- EXPLAIN 
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    u.user_id,
    u.name,
    COUNT(t.ticket_id) AS unpaid_ticket_count,
    COALESCE(SUM(t.amount), 0) - COALESCE(SUM(pay.total_paid), 0) AS total_balance_due
FROM users u
JOIN vehicles v
    ON v.user_id = u.user_id
JOIN tickets t
    ON t.vehicle_id = v.vehicle_id
LEFT JOIN (
    SELECT
        ticket_id,
        SUM(amount) AS total_paid
    FROM payments
    GROUP BY ticket_id
) pay
    ON pay.ticket_id = t.ticket_id
WHERE t.status IN ('unpaid', 'partial')
GROUP BY u.user_id, u.name
ORDER BY total_balance_due DESC, u.name;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    r.reservation_id,
    r.user_id,
    r.spot_id,
    r.start_ts,
    r.end_ts,
    r.status
FROM reservations r
WHERE r.status IN ('pending', 'confirmed')
  AND r.start_ts < '2026-04-20 12:00:00'
  AND r.end_ts > '2026-04-20 10:00:00'
ORDER BY r.spot_id, r.start_ts;

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (se.spot_id)
    se.spot_id,
    s.spot_number,
    l.name AS lot_name,
    se.vehicle_id,
    se.event_type,
    se.event_ts
FROM sensor_events se
JOIN spots s
    ON s.spot_id = se.spot_id
JOIN lots l
    ON l.lot_id = s.lot_id
ORDER BY se.spot_id, se.event_ts DESC, se.sensor_event_id DESC;
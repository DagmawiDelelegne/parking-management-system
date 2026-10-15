create TABLE users (
    user_id INTEGER PRIMARY KEY,
    role VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT chk_users_role
        CHECK (role IN ('student', 'faculty_staff', 'visitor', 'admin', 'officer')),

    CONSTRAINT chk_users_status
        CHECK (status IN ('active', 'inactive', 'suspended'))
);


create TABLE permit_type (
    permit_type_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    user_category VARCHAR(20) NOT NULL,
    max_vehicles INTEGER NOT NULL,
    price NUMERIC (10,2) NOT NULL,

    CONSTRAINT chk_permit_type_user_category
        CHECK (user_category IN ('student', 'faculty_staff', 'visitor')),

    CONSTRAINT chk_permit_type_max_vehicles
        CHECK (max_vehicles > 0),

    CONSTRAINT chk_permit_type_price
        CHECK (price >= 0)
);


create TABLE lots (
    lot_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    zone_code VARCHAR(20) NOT NULL,
    location_desc VARCHAR(200),
    visitor_allowed BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE vehicles (
    vehicle_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    plate_no VARCHAR(20) NOT NULL,
    plate_state VARCHAR(20) NOT NULL,
    vehicle_type VARCHAR(20) NOT NULL,

    CONSTRAINT uq_vehicle_plate UNIQUE (plate_no, plate_state),

    CONSTRAINT fk_vehicles_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT chk_vehicle_type
        CHECK (vehicle_type IN ('sedan', 'suv', 'truck', 'van', 'motorcycle', 'other'))
);


CREATE TABLE permits (
    permit_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    permit_type_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    CONSTRAINT fk_permits_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT fk_permits_permit_type
        FOREIGN KEY (permit_type_id) REFERENCES permit_type(permit_type_id),

    CONSTRAINT chk_permits_status
        CHECK (status IN ('active', 'expired', 'cancelled', 'pending')),

    CONSTRAINT chk_permits_dates
        CHECK (end_date >= start_date)
);

CREATE TABLE spots (
    spot_id INTEGER PRIMARY KEY,
    lot_id INTEGER NOT NULL,
    spot_number VARCHAR(20) NOT NULL,
    spot_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    is_reservable BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_spots_lot
        FOREIGN KEY (lot_id) REFERENCES lots(lot_id),

    CONSTRAINT uq_spot_in_lot
        UNIQUE (lot_id, spot_number),

    CONSTRAINT chk_spot_type
        CHECK (spot_type IN ('student', 'faculty_staff', 'visitor', 'general', 'accessible', 'ev')),

    CONSTRAINT chk_spot_status
        CHECK (status IN ('available', 'occupied', 'maintenance', 'closed'))
);

CREATE TABLE permit_vehicle (
    permit_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    linked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_permit_vehicle
        PRIMARY KEY (permit_id, vehicle_id),

    CONSTRAINT fk_permit_vehicle_permit
        FOREIGN KEY (permit_id) REFERENCES permits(permit_id),

    CONSTRAINT fk_permit_vehicle_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
);


CREATE TABLE reservations (
    reservation_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    spot_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    start_ts TIMESTAMP NOT NULL,
    end_ts TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_reservations_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT fk_reservations_spot
        FOREIGN KEY (spot_id) REFERENCES spots(spot_id),

    CONSTRAINT fk_reservations_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),

    CONSTRAINT chk_reservation_times
        CHECK (end_ts > start_ts),

    CONSTRAINT chk_reservation_status
        CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed'))
);


CREATE TABLE tickets (
    ticket_id INTEGER PRIMARY KEY,
    vehicle_id INTEGER NOT NULL,
    spot_id INTEGER NOT NULL,
    issued_at TIMESTAMP NOT NULL,
    violation_code VARCHAR(30) NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_tickets_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),

    CONSTRAINT fk_tickets_spot
        FOREIGN KEY (spot_id) REFERENCES spots(spot_id),

    CONSTRAINT chk_ticket_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_ticket_status
        CHECK (status IN ('unpaid', 'partial', 'paid', 'void'))
);


CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY,
    ticket_id INTEGER NOT NULL,
    paid_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount NUMERIC(10,2) NOT NULL,
    method VARCHAR(20) NOT NULL,

    CONSTRAINT fk_payments_ticket
        FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),

    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_payment_method
        CHECK (method IN ('card', 'cash', 'online', 'waived'))
);



CREATE TABLE sensor_events (
    sensor_event_id INTEGER PRIMARY KEY,
    spot_id INTEGER NOT NULL,
    vehicle_id INTEGER,
    event_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_type VARCHAR(30) NOT NULL,
    note VARCHAR(200),

    CONSTRAINT fk_sensor_events_spot
        FOREIGN KEY (spot_id) REFERENCES spots(spot_id),

    CONSTRAINT fk_sensor_events_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),

    CONSTRAINT chk_sensor_event_type
        CHECK (event_type IN ('entry', 'exit', 'manual_occupied', 'manual_available'))
);


CREATE OR REPLACE FUNCTION issue_permit(
    p_user_id INTEGER,
    p_permit_type_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_role VARCHAR(20);
    v_user_status VARCHAR(20);
    v_user_category VARCHAR(20);
    v_new_permit_id INTEGER;
BEGIN
    IF p_end_date < p_start_date THEN
        RAISE EXCEPTION 'Permit end date cannot be earlier than start date.';
    END IF;

    SELECT role, status
    INTO v_user_role, v_user_status
    FROM users
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist.', p_user_id;
    END IF;

    IF v_user_status <> 'active' THEN
        RAISE EXCEPTION 'Only active users can receive permits.';
    END IF;

    SELECT user_category
    INTO v_user_category
    FROM permit_type
    WHERE permit_type_id = p_permit_type_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Permit type % does not exist.', p_permit_type_id;
    END IF;

    IF v_user_role <> v_user_category THEN
        RAISE EXCEPTION 'User role % is not eligible for permit category %.', v_user_role, v_user_category;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM permits p
        WHERE p.user_id = p_user_id
          AND p.permit_type_id = p_permit_type_id
          AND p.status IN ('active', 'pending')
          AND NOT (p.end_date < p_start_date OR p.start_date > p_end_date)
    ) THEN
        RAISE EXCEPTION 'Overlapping permit already exists for this user and permit type.';
    END IF;

    SELECT COALESCE(MAX(permit_id), 0) + 1
    INTO v_new_permit_id
    FROM permits;

    INSERT INTO permits (permit_id, user_id, permit_type_id, status, start_date, end_date)
    VALUES (
        v_new_permit_id,
        p_user_id,
        p_permit_type_id,
        CASE
            WHEN CURRENT_DATE BETWEEN p_start_date AND p_end_date THEN 'active'
            ELSE 'pending'
        END,
        p_start_date,
        p_end_date
    );

    RETURN v_new_permit_id;
END;
$$;


CREATE OR REPLACE FUNCTION apply_sensor_event_to_spot()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.event_type IN ('entry', 'manual_occupied') THEN
        UPDATE spots
        SET status = 'occupied'
        WHERE spot_id = NEW.spot_id
          AND status NOT IN ('maintenance', 'closed');

    ELSIF NEW.event_type IN ('exit', 'manual_available') THEN
        UPDATE spots
        SET status = 'available'
        WHERE spot_id = NEW.spot_id
          AND status NOT IN ('maintenance', 'closed');
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_sensor_events_update_spot
AFTER INSERT ON sensor_events
FOR EACH ROW
EXECUTE FUNCTION apply_sensor_event_to_spot();


CREATE OR REPLACE PROCEDURE auto_ticketing(
    p_scan_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_new_ticket_id INTEGER;
BEGIN
    FOR rec IN
        SELECT DISTINCT ON (se.spot_id)
               se.spot_id,
               se.vehicle_id,
               se.event_ts,
               se.event_type
        FROM sensor_events se
        WHERE se.event_ts <= p_scan_time
        ORDER BY se.spot_id, se.event_ts DESC, se.sensor_event_id DESC
    LOOP
        IF rec.event_type NOT IN ('entry', 'manual_occupied') OR rec.vehicle_id IS NULL THEN
            CONTINUE;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM tickets t
            WHERE t.vehicle_id = rec.vehicle_id
              AND t.spot_id = rec.spot_id
              AND DATE(t.issued_at) = DATE(p_scan_time)
              AND t.status <> 'void'
        ) THEN
            CONTINUE;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM permit_vehicle pv
            JOIN permits p
              ON p.permit_id = pv.permit_id
            WHERE pv.vehicle_id = rec.vehicle_id
              AND p.status = 'active'
              AND DATE(p_scan_time) BETWEEN p.start_date AND p.end_date
        ) THEN
            SELECT COALESCE(MAX(ticket_id), 0) + 1
            INTO v_new_ticket_id
            FROM tickets;

            INSERT INTO tickets (
                ticket_id,
                vehicle_id,
                spot_id,
                issued_at,
                violation_code,
                amount,
                status
            )
            VALUES (
                v_new_ticket_id,
                rec.vehicle_id,
                rec.spot_id,
                p_scan_time,
                'NO_PERMIT',
                50.00,
                'unpaid'
            );
        END IF;
    END LOOP;
END;
$$;


CREATE OR REPLACE VIEW current_active_permits AS
SELECT
    p.permit_id,
    p.user_id,
    u.name AS user_name,
    u.role,
    pt.name AS permit_type_name,
    p.start_date,
    p.end_date,
    p.status
FROM permits p
JOIN users u
    ON u.user_id = p.user_id
JOIN permit_type pt
    ON pt.permit_type_id = p.permit_type_id
WHERE p.status = 'active'
  AND CURRENT_DATE BETWEEN p.start_date AND p.end_date;


CREATE OR REPLACE VIEW current_lot_availability AS
SELECT
    l.lot_id,
    l.name AS lot_name,
    COUNT(*) AS total_spots,
    COUNT(*) FILTER (WHERE s.status = 'available') AS available_spots,
    COUNT(*) FILTER (WHERE s.status = 'occupied') AS occupied_spots,
    COUNT(*) FILTER (WHERE s.status = 'maintenance') AS maintenance_spots,
    COUNT(*) FILTER (WHERE s.status = 'closed') AS closed_spots
FROM lots l
JOIN spots s
    ON s.lot_id = l.lot_id
GROUP BY l.lot_id, l.name;






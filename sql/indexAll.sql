CREATE INDEX idx_vehicles_user_id
    ON vehicles(user_id);

CREATE INDEX idx_permits_user_id
    ON permits(user_id);

CREATE INDEX idx_permits_permit_type_id
    ON permits(permit_type_id);

CREATE INDEX idx_spots_lot_id
    ON spots(lot_id);

CREATE INDEX idx_reservations_spot_time
    ON reservations(spot_id, start_ts, end_ts);

CREATE INDEX idx_reservations_user_id
    ON reservations(user_id);

CREATE INDEX idx_tickets_vehicle_id
    ON tickets(vehicle_id);

CREATE INDEX idx_payments_ticket_id
    ON payments(ticket_id);

CREATE INDEX idx_permits_status_dates
    ON permits(status, start_date, end_date);

CREATE INDEX idx_permit_vehicle_vehicle_id_permit_id
    ON permit_vehicle(vehicle_id, permit_id);

CREATE INDEX idx_tickets_status_vehicle_id
    ON tickets(status, vehicle_id);

CREATE INDEX idx_reservations_status_spot_time
    ON reservations(status, spot_id, start_ts, end_ts);

CREATE INDEX idx_sensor_events_spot_event_ts
    ON sensor_events(spot_id, event_ts DESC, sensor_event_id DESC);
-- A6 transaction demo. Use two pgAdmin Query Tool windows.
-- Do not run the full file in one window.

-- Run once before starting.
DELETE FROM reservations WHERE reservation_id IN (9001, 9002, 9003, 9004);

-- PART A: double booking without locking

-- SESSION 1: run, then wait.
BEGIN;
SELECT COUNT(*) AS conflicts
FROM reservations
WHERE spot_id = 5
  AND status IN ('pending', 'confirmed')
  AND NOT (end_ts <= '2026-05-01 08:00:00' OR start_ts >= '2026-05-01 10:00:00');

INSERT INTO reservations (reservation_id, user_id, spot_id, vehicle_id, start_ts, end_ts, status)
VALUES (9001, 5, 5, 5, '2026-05-01 08:00:00', '2026-05-01 10:00:00', 'confirmed');

-- SESSION 2: run, then commit.
BEGIN;
SELECT COUNT(*) AS conflicts
FROM reservations
WHERE spot_id = 5
  AND status IN ('pending', 'confirmed')
  AND NOT (end_ts <= '2026-05-01 09:00:00' OR start_ts >= '2026-05-01 11:00:00');

INSERT INTO reservations (reservation_id, user_id, spot_id, vehicle_id, start_ts, end_ts, status)
VALUES (9002, 6, 5, 6, '2026-05-01 09:00:00', '2026-05-01 11:00:00', 'confirmed');
COMMIT;

-- SESSION 1: commit.
COMMIT;

-- EITHER SESSION: both rows should appear.
SELECT reservation_id, spot_id, start_ts, end_ts, status
FROM reservations
WHERE reservation_id IN (9001, 9002)
ORDER BY reservation_id;

-- Cleanup before Part B.
DELETE FROM reservations WHERE reservation_id IN (9001, 9002, 9003, 9004);

-- PART B: prevention with SELECT ... FOR UPDATE

-- SESSION 1: run, then wait before COMMIT.
BEGIN;
SELECT * FROM spots WHERE spot_id = 5 FOR UPDATE;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM reservations
        WHERE spot_id = 5
          AND status IN ('pending', 'confirmed')
          AND NOT (end_ts <= '2026-05-01 08:00:00' OR start_ts >= '2026-05-01 10:00:00')
    ) THEN
        RAISE EXCEPTION 'spot already reserved for the requested time window';
    END IF;

    INSERT INTO reservations (reservation_id, user_id, spot_id, vehicle_id, start_ts, end_ts, status)
    VALUES (9003, 5, 5, 5, '2026-05-01 08:00:00', '2026-05-01 10:00:00', 'confirmed');
END $$;

-- SESSION 2: run. It should wait at the lock.
BEGIN;
SELECT * FROM spots WHERE spot_id = 5 FOR UPDATE;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM reservations
        WHERE spot_id = 5
          AND status IN ('pending', 'confirmed')
          AND NOT (end_ts <= '2026-05-01 09:00:00' OR start_ts >= '2026-05-01 11:00:00')
    ) THEN
        RAISE EXCEPTION 'spot already reserved for the requested time window';
    END IF;

    INSERT INTO reservations (reservation_id, user_id, spot_id, vehicle_id, start_ts, end_ts, status)
    VALUES (9004, 6, 5, 6, '2026-05-01 09:00:00', '2026-05-01 11:00:00', 'confirmed');
END $$;
COMMIT;

-- SESSION 1: commit after Session 2 is waiting.
COMMIT;

-- SESSION 2: run after the error.
ROLLBACK;

-- EITHER SESSION: only 9003 should appear.
SELECT reservation_id, spot_id, start_ts, end_ts, status
FROM reservations
WHERE reservation_id IN (9003, 9004)
ORDER BY reservation_id;

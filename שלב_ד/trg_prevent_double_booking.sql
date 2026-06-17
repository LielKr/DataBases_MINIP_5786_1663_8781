-- =========================================================
-- trg_prevent_double_booking.sql - שלב ד: טריגר מניעת כפל הזמנות
-- מונע שיבוץ חדרים כפולים או שיבוץ חדרים שנמצאים בשיפוצים/תחזוקה
-- =========================================================

CREATE OR REPLACE FUNCTION fn_trg_prevent_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    v_new_check_in DATE;
    v_new_check_out DATE;
    v_room_status VARCHAR(20);
    v_overlap_booking_id INT;
BEGIN
    -- Get check-in and check-out dates for the booking being assigned
    SELECT check_in_date, check_out_date INTO v_new_check_in, v_new_check_out
    FROM BOOKINGS
    WHERE booking_id = NEW.booking_id;

    -- Check if room exists and get its status
    SELECT physical_status INTO v_room_status
    FROM ROOMS
    WHERE room_id = NEW.room_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Room % does not exist.', NEW.room_id;
    END IF;

    -- Check if the room is currently under maintenance or out of order
    IF v_room_status IN ('MAINTENANCE', 'OUT_OF_ORDER') THEN
        RAISE EXCEPTION 'Cannot assign Room %. Room physical status is %.', NEW.room_id, v_room_status;
    END IF;

    -- Check for overlapping bookings for the same room
    SELECT ra.booking_id INTO v_overlap_booking_id
    FROM ROOM_ASSIGNMENTS ra
    JOIN BOOKINGS b ON ra.booking_id = b.booking_id
    WHERE ra.room_id = NEW.room_id
      AND ra.booking_id != NEW.booking_id -- Exclude current booking in case of update
      AND b.check_in_date < v_new_check_out
      AND b.check_out_date > v_new_check_in
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION 'Cannot assign Room %: Overlaps with Booking %.', NEW.room_id, v_overlap_booking_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_double_booking ON ROOM_ASSIGNMENTS;

CREATE TRIGGER trg_prevent_double_booking
BEFORE INSERT OR UPDATE ON ROOM_ASSIGNMENTS
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_double_booking();

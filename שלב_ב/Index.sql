-- =========================================================
-- Recommended indexes for efficiency
-- These indexes help the JOIN, WHERE, GROUP BY and date filters.
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_bookings_guest_id
ON BOOKINGS(guest_id);

CREATE INDEX IF NOT EXISTS idx_bookings_source_id
ON BOOKINGS(source_id);

CREATE INDEX IF NOT EXISTS idx_bookings_dates
ON BOOKINGS(check_in_date, check_out_date);

CREATE INDEX IF NOT EXISTS idx_room_assignments_booking_id
ON ROOM_ASSIGNMENTS(booking_id);

CREATE INDEX IF NOT EXISTS idx_room_assignments_room_id
ON ROOM_ASSIGNMENTS(room_id);

CREATE INDEX IF NOT EXISTS idx_check_ins_outs_booking_id
ON CHECK_INS_OUTS(booking_id);

CREATE INDEX IF NOT EXISTS idx_rooms_status
ON ROOMS(physical_status);
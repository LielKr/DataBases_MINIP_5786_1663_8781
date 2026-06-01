-- אילוץ 1: תאריך הצ'ק-אאוט חייב להיות אחרי תאריך הצ'ק-אין
ALTER TABLE BOOKINGS
ADD CONSTRAINT chk_check_out_after_in
CHECK (check_out_date > check_in_date);

-- אילוץ 2: מספר האורחים בהזמנה חייב להיות גדול מ-0
ALTER TABLE BOOKINGS
ADD CONSTRAINT chk_at_least_one_guest
CHECK (num_guests > 0);

-- אילוץ 3: עמלת מקור ההזמנה (Commission Rate) חייבת להיות בין 0 ל-100
ALTER TABLE BOOKING_SOURCES
ADD CONSTRAINT chk_commission_range
CHECK (commission_rate >= 0 AND commission_rate <= 100);


--בדיקה שהאילוצים עובדים
-- ניסיון להכניס הזמנה עם 0 אורחים (יכשיל את אילוץ 2)
INSERT INTO BOOKINGS (booking_id, guest_id, source_id, check_in_date, check_out_date, num_guests, total_price, booking_status)
VALUES (9999, 1, 1, '2026-06-01', '2026-06-05', 0, 500, 'CONFIRMED');
-- =========================================================
-- Queries.sql
-- Hotel Reservations and Front Office Database System
-- Stage B: Queries and Constraints
-- Assumption: PostgreSQL syntax
-- =========================================================


-- =========================================================
-- Recommended ALTER TABLE changes for Stage B
-- These changes help support statuses and make the queries more useful.
-- =========================================================

ALTER TABLE BOOKINGS
ADD COLUMN IF NOT EXISTS booking_status VARCHAR(20) DEFAULT 'CONFIRMED';

ALTER TABLE BOOKINGS
ADD CONSTRAINT chk_booking_status
CHECK (booking_status IN ('CONFIRMED', 'CANCELLED', 'COMPLETED', 'NO_SHOW'));

ALTER TABLE CHECK_INS_OUTS
ADD COLUMN IF NOT EXISTS created_at DATE DEFAULT CURRENT_DATE;





-- =========================================================
-- SELECT 1
-- Dashboard: upcoming confirmed bookings with guest and booking source
-- Screen: Dashboard / Bookings Management
מציג הזמנות עתידיות שמאושרות.

הוא מחבר בין:

BOOKINGS
GUESTS
BOOKING_SOURCES

כדי להציג לא רק מספר הזמנה, אלא גם שם אורח, מקור הזמנה, תאריכים, מספר אורחים ומחיר.

מתאים למסך: Dashboard / Bookings
-- =========================================================

SELECT
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    bs.source_name,
    b.check_in_date,
    b.check_out_date,
    b.num_guests,
    b.total_price,
    b.booking_status
FROM BOOKINGS b
JOIN GUESTS g
    ON b.guest_id = g.guest_id
JOIN BOOKING_SOURCES bs
    ON b.source_id = bs.source_id
WHERE b.check_in_date >= CURRENT_DATE
  AND b.booking_status = 'CONFIRMED'
ORDER BY b.check_in_date ASC, b.booking_id ASC;


-- =========================================================
-- SELECT 2A
מציג הכנסות לפי חודש ושנה.

הוא מחשב:

כמה הזמנות היו בכל חודש
סך ההכנסות
מחיר ממוצע להזמנה

יש כאן GROUP BY ופירוק תאריך ל־YEAR ו־MONTH.
-- Monthly revenue by year and month
-- Includes date decomposition: year and month
-- Screen: Dashboard / Manager report
-- =========================================================

SELECT
    EXTRACT(YEAR FROM b.check_in_date) AS booking_year,
    EXTRACT(MONTH FROM b.check_in_date) AS booking_month,
    COUNT(*) AS number_of_bookings,
    SUM(b.total_price) AS total_revenue,
    AVG(b.total_price) AS average_booking_price
FROM BOOKINGS b
WHERE b.booking_status IN ('CONFIRMED', 'COMPLETED')
GROUP BY
    EXTRACT(YEAR FROM b.check_in_date),
    EXTRACT(MONTH FROM b.check_in_date)
ORDER BY booking_year, booking_month;


-- =========================================================
-- SELECT 2B
עושה אותו דבר כמו 2A, אבל קודם יוצר תת־שאילתה שמפרקת את התאריך לשנה וחודש, ואז עושה עליה GROUP BY.

ההבדל:
2A יותר ישירה ופשוטה.
2B מדגימה שימוש בתת־שאילתה.
-- Same result using a subquery first
-- Less direct, but useful for comparing query structure
-- =========================================================

SELECT
    monthly.booking_year,
    monthly.booking_month,
    COUNT(*) AS number_of_bookings,
    SUM(monthly.total_price) AS total_revenue,
    AVG(monthly.total_price) AS average_booking_price
FROM
(
    SELECT
        booking_id,
        total_price,
        EXTRACT(YEAR FROM check_in_date) AS booking_year,
        EXTRACT(MONTH FROM check_in_date) AS booking_month
    FROM BOOKINGS
    WHERE booking_status IN ('CONFIRMED', 'COMPLETED')
) monthly
GROUP BY monthly.booking_year, monthly.booking_month
ORDER BY monthly.booking_year, monthly.booking_month;


-- =========================================================
-- SELECT 3A
-- Available rooms by room type
-- Screen: Front Office / Rooms
-- =========================================================

SELECT
    rt.type_name,
    rt.base_price,
    rt.max_occupancy,
    COUNT(r.room_id) AS available_rooms
FROM ROOM_TYPES rt
JOIN ROOMS r
    ON rt.type_id = r.type_id
WHERE r.physical_status = 'AVAILABLE'
GROUP BY
    rt.type_name,
    rt.base_price,
    rt.max_occupancy
ORDER BY available_rooms DESC, rt.type_name;


-- =========================================================
-- SELECT 3B
3A בדרך כלל יעילה יותר כי היא עושה JOIN ו־GROUP BY.
3B יכולה להיות פחות יעילה כי היא סופרת חדרים בנפרד עבור כל סוג חדר.
-- Same result using a correlated subquery
-- Usually less efficient on large tables because it may calculate per room type
-- =========================================================

SELECT
    rt.type_name,
    rt.base_price,
    rt.max_occupancy,
    (
        SELECT COUNT(*)
        FROM ROOMS r
        WHERE r.type_id = rt.type_id
          AND r.physical_status = 'AVAILABLE'
    ) AS available_rooms
FROM ROOM_TYPES rt
ORDER BY available_rooms DESC, rt.type_name;


-- =========================================================
-- SELECT 4A
-- Guests with number of bookings and total spending
-- Screen: Guests Management
-- =========================================================

SELECT
    g.guest_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    g.phone,
    g.email,
    COUNT(b.booking_id) AS total_bookings,
    COALESCE(SUM(b.total_price), 0) AS total_spent
FROM GUESTS g
LEFT JOIN BOOKINGS b
    ON g.guest_id = b.guest_id
GROUP BY
    g.guest_id,
    g.first_name,
    g.last_name,
    g.phone,
    g.email
ORDER BY total_spent DESC, total_bookings DESC;


-- =========================================================
-- SELECT 4B
4A בדרך כלל יעילה יותר למערכת גדולה.
4B יותר קלה להבנה לפעמים, אבל עלולה לחשב שוב ושוב לכל אורח.
-- Same result using subqueries in SELECT
-- Easier to read sometimes, but may be less efficient for many guests
-- =========================================================

SELECT
    g.guest_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    g.phone,
    g.email,
    (
        SELECT COUNT(*)
        FROM BOOKINGS b
        WHERE b.guest_id = g.guest_id
    ) AS total_bookings,
    (
        SELECT COALESCE(SUM(b.total_price), 0)
        FROM BOOKINGS b
        WHERE b.guest_id = g.guest_id
    ) AS total_spent
FROM GUESTS g
ORDER BY total_spent DESC, total_bookings DESC;


-- =========================================================
-- SELECT 5A
-- Bookings that still do not have any assigned room
-- Screen: Bookings Management / Front Office
-- =========================================================

SELECT
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    b.check_in_date,
    b.check_out_date,
    b.num_guests,
    b.booking_status
FROM BOOKINGS b
JOIN GUESTS g
    ON b.guest_id = g.guest_id
LEFT JOIN ROOM_ASSIGNMENTS ra
    ON b.booking_id = ra.booking_id
WHERE ra.assignment_id IS NULL
  AND b.booking_status = 'CONFIRMED'
ORDER BY b.check_in_date;


-- =========================================================
-- SELECT 5B
-- Same result using NOT EXISTS
-- Often efficient and clear for checking that no matching row exists
-- =========================================================

SELECT
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    b.check_in_date,
    b.check_out_date,
    b.num_guests,
    b.booking_status
FROM BOOKINGS b
JOIN GUESTS g
    ON b.guest_id = g.guest_id
WHERE NOT EXISTS
(
    SELECT 1
    FROM ROOM_ASSIGNMENTS ra
    WHERE ra.booking_id = b.booking_id
)
AND b.booking_status = 'CONFIRMED'
ORDER BY b.check_in_date;


-- =========================================================
-- SELECT 6
-- Booking source performance with commission calculation
-- Screen: Dashboard / Manager report
-- =========================================================

SELECT
    bs.source_id,
    bs.source_name,
    bs.commission_rate,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_price) AS gross_revenue,
    SUM(b.total_price * bs.commission_rate / 100) AS estimated_commission,
    SUM(b.total_price - (b.total_price * bs.commission_rate / 100)) AS net_revenue
FROM BOOKING_SOURCES bs
JOIN BOOKINGS b
    ON bs.source_id = b.source_id
WHERE b.booking_status IN ('CONFIRMED', 'COMPLETED')
GROUP BY
    bs.source_id,
    bs.source_name,
    bs.commission_rate
ORDER BY net_revenue DESC;


-- =========================================================
-- SELECT 7
-- Actual check-in/check-out comparison with planned dates
-- Uses date decomposition into day, month and year
-- Screen: Front Office / Check-in and Check-out
-- =========================================================

SELECT
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    b.check_in_date AS planned_check_in,
    cio.actual_check_in,
    EXTRACT(DAY FROM cio.actual_check_in) AS actual_check_in_day,
    EXTRACT(MONTH FROM cio.actual_check_in) AS actual_check_in_month,
    EXTRACT(YEAR FROM cio.actual_check_in) AS actual_check_in_year,
    b.check_out_date AS planned_check_out,
    cio.actual_check_out,
    CASE
        WHEN cio.actual_check_in > b.check_in_date THEN 'LATE_CHECK_IN'
        WHEN cio.actual_check_in < b.check_in_date THEN 'EARLY_CHECK_IN'
        WHEN cio.actual_check_in = b.check_in_date THEN 'ON_TIME'
        ELSE 'NOT_CHECKED_IN_YET'
    END AS check_in_status
FROM BOOKINGS b
JOIN GUESTS g
    ON b.guest_id = g.guest_id
LEFT JOIN CHECK_INS_OUTS cio
    ON b.booking_id = cio.booking_id
ORDER BY b.check_in_date DESC, b.booking_id;


-- =========================================================
-- SELECT 8
-- Rooms that are assigned to bookings during a selected date range
-- Screen: Front Office / Room availability search
-- Replace the dates with parameters in the GUI later.
-- =========================================================

SELECT
    r.room_id,
    r.floor,
    rt.type_name,
    r.physical_status,
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    b.check_in_date,
    b.check_out_date
FROM ROOMS r
JOIN ROOM_TYPES rt
    ON r.type_id = rt.type_id
JOIN ROOM_ASSIGNMENTS ra
    ON r.room_id = ra.room_id
JOIN BOOKINGS b
    ON ra.booking_id = b.booking_id
JOIN GUESTS g
    ON b.guest_id = g.guest_id
WHERE b.booking_status = 'CONFIRMED'
  AND b.check_in_date < DATE '2026-08-10'
  AND b.check_out_date > DATE '2026-08-01'
ORDER BY r.room_id, b.check_in_date;


-- =========================================================
-- UPDATE 1
מעדכן חדרים לסטטוס OCCUPIED אם האורח כבר עשה צ׳ק־אין בפועל 
ועדיין לא עשה צ׳ק־אאוט.
-- Mark rooms as OCCUPIED when the guest actually checked in
-- Screen: Front Office / Check In button
-- =========================================================

UPDATE ROOMS r
SET physical_status = 'OCCUPIED'
WHERE r.room_id IN
(
    SELECT ra.room_id
    FROM ROOM_ASSIGNMENTS ra
    JOIN CHECK_INS_OUTS cio
        ON ra.booking_id = cio.booking_id
    WHERE cio.actual_check_in IS NOT NULL
      AND cio.actual_check_out IS NULL
);


-- =========================================================
-- UPDATE 2
-- Mark bookings as COMPLETED when actual check-out exists
-- Screen: Front Office / Check Out button

מעדכן הזמנות לסטטוס COMPLETED אם יש להן תאריך צ׳ק־אאוט בפועל.
-- =========================================================

UPDATE BOOKINGS b
SET booking_status = 'COMPLETED'
WHERE EXISTS
(
    SELECT 1
    FROM CHECK_INS_OUTS cio
    WHERE cio.booking_id = b.booking_id
      AND cio.actual_check_out IS NOT NULL
);


-- =========================================================
-- UPDATE 3

-- Give a 10% price increase to future confirmed bookings from high-commission sources
-- Screen: Manager / Pricing action

מעלה ב־10% את המחיר של הזמנות עתידיות שמגיעות ממקורות עם עמלה גבוהה מ־15%.

המטרה: להראות שאילתה מורכבת עם תת־שאילתה ועדכון עסקי.
-- =========================================================

UPDATE BOOKINGS b
SET total_price = total_price * 1.10
WHERE b.booking_status = 'CONFIRMED'
  AND b.check_in_date > CURRENT_DATE
  AND b.source_id IN
  (
      SELECT bs.source_id
      FROM BOOKING_SOURCES bs
      WHERE bs.commission_rate > 15
  );


-- =========================================================
-- DELETE 1
-- Delete room assignments of cancelled future bookings
-- Must be done before deleting the booking itself if there is no ON DELETE CASCADE.
-- Screen: Admin maintenance

מוחק שיוכי חדרים של הזמנות עתידיות שבוטלו.
-- =========================================================

DELETE FROM ROOM_ASSIGNMENTS ra
WHERE ra.booking_id IN
(
    SELECT b.booking_id
    FROM BOOKINGS b
    WHERE b.booking_status = 'CANCELLED'
      AND b.check_in_date > CURRENT_DATE
);


-- =========================================================
-- DELETE 2
-- Delete old check-in/out logs for cancelled or no-show bookings
-- Screen: Admin maintenance

מוחק רשומות צ׳ק־אין/צ׳ק־אאוט ריקות של הזמנות שבוטלו או שהאורח לא הגיע.
-- =========================================================

DELETE FROM CHECK_INS_OUTS cio
WHERE cio.booking_id IN
(
    SELECT b.booking_id
    FROM BOOKINGS b
    WHERE b.booking_status IN ('CANCELLED', 'NO_SHOW')
)
AND cio.actual_check_in IS NULL
AND cio.actual_check_out IS NULL;


-- =========================================================
-- DELETE 3
-- Delete booking sources that were never used
-- Screen: Admin / Booking sources management

מוחק מקורות הזמנה שלא השתמשו בהם אף פעם.

כלומר מקור שאין אף הזמנה שמפנה אליו.
-- =========================================================

DELETE FROM BOOKING_SOURCES bs
WHERE NOT EXISTS
(
    SELECT 1
    FROM BOOKINGS b
    WHERE b.source_id = bs.source_id
);

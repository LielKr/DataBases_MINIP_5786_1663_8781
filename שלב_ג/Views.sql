-- =============================================
-- Views.sql - שלב ג: מבטים ושאילתות
-- =============================================

-- =============================================
-- מבט 1: מנקודת המבט של האגף המקורי שלנו (חדרים והזמנות)
-- שם: v_booking_room_details
-- תיאור: מבט שמשלב הזמנות עם שיבוץ חדרים וסוגי חדרים.
--         מציג לכל הזמנה את פרטי החדר שהוקצה, הקומה, סוג החדר והמחיר.
--         משלב 4 טבלאות: BOOKINGS, ROOM_ASSIGNMENTS, ROOMS, ROOM_TYPES
-- =============================================

CREATE OR REPLACE VIEW v_booking_room_details AS
SELECT
    b.booking_id,
    b.booking_date,
    b.check_in_date,
    b.check_out_date,
    b.total_price,
    b.num_guests,
    r.room_id,
    r.floor,
    r.physical_status,
    rt.type_name AS room_type,
    rt.base_price AS room_base_price,
    rt.max_occupancy,
    bs.source_name AS booking_source
FROM BOOKINGS b
JOIN ROOM_ASSIGNMENTS ra ON b.booking_id = ra.booking_id
JOIN ROOMS r ON ra.room_id = r.room_id
JOIN ROOM_TYPES rt ON r.type_id = rt.type_id
JOIN BOOKING_SOURCES bs ON b.source_id = bs.source_id;

-- -------------------------------------------------
-- שאילתה 1.1 על המבט: הזמנות שבהן מספר האורחים חורג מתפוסת החדר
-- מטרה: לזהות הזמנות בעייתיות שבהן הוקצה חדר קטן מדי
-- -------------------------------------------------
SELECT
    booking_id,
    room_id,
    num_guests,
    room_type,
    max_occupancy,
    booking_source
FROM v_booking_room_details
WHERE num_guests > max_occupancy
ORDER BY booking_id;

-- -------------------------------------------------
-- שאילתה 1.2 על המבט: הכנסה ממוצעת וסה"כ לפי מקור הזמנה
-- מטרה: להבין איזה ערוץ הזמנה מביא את ההכנסה הגבוהה ביותר
-- -------------------------------------------------
SELECT
    booking_source,
    COUNT(*) AS total_bookings,
    ROUND(AVG(total_price), 2) AS avg_price,
    SUM(total_price) AS total_revenue
FROM v_booking_room_details
GROUP BY booking_source
ORDER BY total_revenue DESC;


-- =============================================
-- מבט 2: מנקודת המבט של האגף שקיבלנו (אורחים, שהיות ותשלומים)
-- שם: v_guest_stay_summary
-- תיאור: מבט שמשלב אורחים עם שהיות, תשלומים ופידבק.
--         מציג לכל אורח את פרטיו, שהיותיו, סכומי תשלום ודירוג.
--         משלב 4 טבלאות: GUESTS, STAY_RECORD, PAYMENT, GUEST_FEEDBACK
-- =============================================

CREATE OR REPLACE VIEW v_guest_stay_summary AS
SELECT
    g.guest_id,
    g.first_name,
    g.last_name,
    g.phone,
    g.email,
    sr.stay_id,
    sr.check_in_date,
    sr.check_out_date,
    (sr.check_out_date - sr.check_in_date) AS nights,
    p.payment_id,
    p.amount AS payment_amount,
    p.payment_method,
    p.payment_status,
    gf.rating AS feedback_rating,
    gf.comments AS feedback_comments
FROM GUESTS g
JOIN STAY_RECORD sr ON g.guest_id = sr.guest_id
LEFT JOIN PAYMENT p ON sr.stay_id = p.stay_id
LEFT JOIN GUEST_FEEDBACK gf ON sr.stay_id = gf.stay_id;

-- -------------------------------------------------
-- שאילתה 2.1 על המבט: אורחים עם דירוג ממוצע גבוה מ-4
-- מטרה: לזהות אורחים מרוצים שאפשר להציע להם מנוי נאמנות
-- -------------------------------------------------
SELECT
    guest_id,
    first_name,
    last_name,
    COUNT(stay_id) AS total_stays,
    ROUND(AVG(feedback_rating), 1) AS avg_rating
FROM v_guest_stay_summary
WHERE feedback_rating IS NOT NULL
GROUP BY guest_id, first_name, last_name
HAVING AVG(feedback_rating) >= 4
ORDER BY avg_rating DESC;

-- -------------------------------------------------
-- שאילתה 2.2 על המבט: סיכום תשלומים לפי אורח ושיטת תשלום
-- מטרה: לראות העדפות תשלום וסך הוצאות של כל אורח
-- -------------------------------------------------
SELECT
    first_name || ' ' || last_name AS guest_name,
    payment_method,
    COUNT(*) AS num_payments,
    SUM(payment_amount) AS total_paid
FROM v_guest_stay_summary
WHERE payment_amount IS NOT NULL
GROUP BY first_name, last_name, payment_method
ORDER BY guest_name, total_paid DESC;

--rollback
-- 1. נבדוק את המצב המקורי של מחיר ההזמנה (למשל עבור הזמנה מספר 1)
SELECT booking_id, total_price, booking_status FROM BOOKINGS WHERE booking_id = 1;

-- 2. נתחיל טרנזקציה
BEGIN;

-- 3. נבצע עדכון (למשל, נהפוך את הסטטוס ל-CANCELLED ונאפס מחיר)
UPDATE BOOKINGS 
SET booking_status = 'CANCELLED', total_price = 0 
WHERE booking_id = 1;

-- 4. נראה את המצב *לאחר העדכון* (בתוך הטרנזקציה) - כאן נראה שהנתונים השתנו!
SELECT booking_id, total_price, booking_status FROM BOOKINGS WHERE booking_id = 1;

-- 5. נבצע ביטול (Rollback)
ROLLBACK;

-- 6. נבדוק שוב את הנתונים - נראה שהם חזרו בדיוק למצב המקורי מסעיף 1
SELECT booking_id, total_price, booking_status FROM BOOKINGS WHERE booking_id = 1;


--commit

-- 1. נבדוק את המצב לפני העדכון
SELECT booking_id, booking_status FROM BOOKINGS WHERE booking_id = 2;

-- 2. נתחיל טרנזקציה
BEGIN;

-- 3. נבצע עדכון (למשל, נעדכן סטטוס ל-COMPLETED)
UPDATE BOOKINGS 
SET booking_status = 'COMPLETED' 
WHERE booking_id = 2;

-- 4. נראה את המצב לאחר העדכון (בתוך הטרנזקציה)
SELECT booking_id, booking_status FROM BOOKINGS WHERE booking_id = 2;

-- 5. נשמור את השינויים קבוע (Commit)
COMMIT;

-- 6. נראה את המצב לאחר ה-COMMIT (השינוי נשאר קבוע בבסיס הנתונים)
SELECT booking_id, booking_status FROM BOOKINGS WHERE booking_id = 2;
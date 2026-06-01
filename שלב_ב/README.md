# 📘 דוח הפרויקט – שלב ב': שאילתות, טרנזקציות ואילוצים

חלק זה מתעד את שלב תשאול בסיס הנתונים, ייעול השאילתות באמצעות אינדקסים, שמירה על שלמות הנתונים באמצעות אילוצים, וניהול טרנזקציות (Commit & Rollback). שאילתות אלו הותאמו במיוחד למסכי המערכת (Dashboard ו-Front Office) ויוצגו בהמשך ב-GUI של המערכת.

---

## 📑 תוכן עניינים – שלב ב'

1. [שאילתות SELECT כפולות והשוואת יעילות](#1-שאילתות-select-כפולות-והשוואת-יעילות)
2. [שאילתות SELECT נוספות ומורכבות](#2-שאילתות-select-נוספות-ומורכבות)
3. [שאילתות UPDATE (עדכון נתונים)](#3-שאילתות-update-עדכון-נתונים)
4. [שאילתות DELETE (מחיקת נתונים)](#4-שאילתות-delete-מחיקת-נתונים)
5. [ניהול טרנזקציות – Rollback & Commit](#5-ניהול-טרנזקציות--rollback--commit)
6. [הוספת אילוצים (Constraints) ובדיקתם](#6-הוספת-אילוצים-constraints-ובדיקתם)
7. [אינדקסים (Indexes) וניתוח זמני ריצה](#7-אינדקסים-indexes-וניתוח-זמני-ריצה)

---

## 1. שאילתות SELECT כפולות והשוואת יעילות

סעיף זה מציג 4 שאילתות שנכתבו בשתי צורות שונות כדי להשוות את יעילותן ואת תוכניות הביצוע (Query Plans) של בסיס הנתונים.

### 📊 שאילתה 2: הכנסות חודשיות לפי שנה וחודש
* **תיאור בעברית:** מציג את סך ההכנסות, מחיר ממוצע להזמנה ומספר ההזמנות הכולל בחלוקה לפי שנה וחודש, עבור הזמנות שאינן מבוטלות. משתמש בפירוק תאריך (`EXTRACT`).
* **מתאים למסך:** Dashboard / מנהל - דוח הכנסות תקופתי.

#### צורה א': שימוש ישיר ב-GROUP BY על פירוק התאריך (2A)
```sql
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
```

##### צילום הרצה ותוצאה צורה א':
![Query1](שלב_ב/images/run1.png)
![Query1](שלב_ב/images/first_5_query1.png)

#### צורה ב': שימוש בתת-שאילתה (Subquery) המפרקת את התאריך תחילה (2B)
```sql
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
```


##### צילום הרצה ותוצאה צורה ב':
#### הסבר הבדלים ויעילות:
מערכת PostgreSQL מייעלת את שתי השאילתות בצורה דומה מאוד בעזרת ה-Query Optimizer שלה. עם זאת, צורה א' (2A) עדיפה ויעילה יותר. היא ניגשת ישירות לטבלה ומבצעת את הקיבוץ והסינון בשלב אחד מבלי ליצור מבנה נתונים זמני בזיכרון (Inline View). צורה ב' יוצרת תת-שאילתה שלא לצורך ומקשה על קריאות הקוד.



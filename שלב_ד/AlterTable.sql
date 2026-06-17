-- =========================================================
-- AlterTable.sql - שלב ד: שינויי מבנה
-- יצירת טבלת לוג תחזוקה לניהול היסטוריית חדרים שיצאו משימוש
-- =========================================================

CREATE TABLE IF NOT EXISTS ROOM_MAINTENANCE_LOG
(
    log_id             SERIAL PRIMARY KEY,
    room_id            INT NOT NULL,
    maintenance_date   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason             VARCHAR(300),
    FOREIGN KEY (room_id) REFERENCES ROOMS(room_id) ON DELETE CASCADE
);

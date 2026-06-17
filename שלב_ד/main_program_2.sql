-- =========================================================
-- main_program_2.sql - שלב ד: תוכנית ראשית 2
-- זימון פונקציה עם Ref Cursor ומעבר על תוצאותיו, וזימון פרוצדורה לתחזוקה
-- =========================================================

DO $$
DECLARE
    v_cursor_name refcursor := 'rooms_cursor';
    v_room_id INT;
    v_floor INT;
    v_phone VARCHAR(10);
    v_room_type VARCHAR(50) := 'Suite';
    v_min_floor INT := 5;
    v_count INT := 0;
BEGIN
    RAISE NOTICE '=== Running Main Program 2 ===';
    
    -- 1. זימון פונקציה להחזרת Ref Cursor של חדרים פנויים
    PERFORM fn_get_available_rooms_by_type(v_room_type, v_min_floor, v_cursor_name);
    
    RAISE NOTICE 'Available rooms of type % (Floor >= %):', v_room_type, v_min_floor;
    
    -- 2. מעבר על תוצאות ה-Cursor והדפסה
    LOOP
        FETCH NEXT FROM v_cursor_name INTO v_room_id, v_floor, v_phone;
        EXIT WHEN NOT FOUND;
        v_count := v_count + 1;
        RAISE NOTICE 'Room % | Floor: % | Phone Extension: %', v_room_id, v_floor, v_phone;
    END LOOP;
    CLOSE v_cursor_name;
    
    RAISE NOTICE 'Total available rooms listed: %', v_count;
    
    -- 3. זימון פרוצדורה לבדיקה והשבתת חדרים עם דירוג נמוך (ציון <= 3)
    RAISE NOTICE 'Scanning feedback and upgrading poorly-rated rooms to MAINTENANCE...';
    CALL pr_upgrade_room_status(3);
    
    RAISE NOTICE '==============================';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Exception caught in Main Program 2: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE pr_upgrade_room_status(
    p_min_rating INT
)
AS $$
DECLARE
    -- Explicit cursor to find rooms with low rating feedbacks
    cur_poor_rooms CURSOR FOR
        SELECT DISTINCT ra.room_id, gf.rating, gf.comments
        FROM GUEST_FEEDBACK gf
        JOIN STAY_RECORD sr ON gf.stay_id = sr.stay_id
        JOIN ROOM_ASSIGNMENTS ra ON sr.booking_id = ra.booking_id
        JOIN ROOMS r ON ra.room_id = r.room_id
        WHERE gf.rating <= p_min_rating 
          AND r.physical_status != 'MAINTENANCE';

    r_room RECORD;
    v_updated_count INT := 0;
BEGIN
    -- Validate rating parameter
    IF p_min_rating NOT BETWEEN 1 AND 5 THEN
        RAISE EXCEPTION 'Invalid rating %. Rating must be between 1 and 5.', p_min_rating;
    END IF;

    -- Open cursor and loop
    OPEN cur_poor_rooms;
    LOOP
        FETCH cur_poor_rooms INTO r_room;
        EXIT WHEN NOT FOUND;

        -- Update room status to MAINTENANCE (DML)
        UPDATE ROOMS 
        SET physical_status = 'MAINTENANCE'
        WHERE room_id = r_room.room_id;

        -- Log the maintenance event (DML)
        INSERT INTO ROOM_MAINTENANCE_LOG (room_id, reason)
        VALUES (r_room.room_id, 'Feedback rating was too low: ' || r_room.rating || '. Comments: ' || COALESCE(r_room.comments, 'None'));

        v_updated_count := v_updated_count + 1;
        RAISE NOTICE 'Room % has been put to MAINTENANCE due to rating %.', r_room.room_id, r_room.rating;
    END LOOP;
    CLOSE cur_poor_rooms;

    RAISE NOTICE 'Completed. Total rooms moved to MAINTENANCE: %.', v_updated_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in pr_upgrade_room_status: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;

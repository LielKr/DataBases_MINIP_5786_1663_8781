CREATE OR REPLACE FUNCTION fn_get_available_rooms_by_type(
    p_type_name VARCHAR,
    p_min_floor INT,
    p_cursor_name refcursor
)
RETURNS refcursor AS $$
DECLARE
    v_type_exists INT;
BEGIN
    -- Validate room type
    SELECT 1 INTO v_type_exists FROM ROOM_TYPES WHERE type_name = p_type_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Room type % does not exist.', p_type_name;
    END IF;

    -- Open the refcursor dynamically for the query
    OPEN p_cursor_name FOR
        SELECT r.room_id, r.floor, r.phone_extension
        FROM ROOMS r
        JOIN ROOM_TYPES rt ON r.type_id = rt.type_id
        WHERE rt.type_name = p_type_name 
          AND r.physical_status = 'AVAILABLE'
          AND r.floor >= p_min_floor
        ORDER BY r.floor, r.room_id;

    RETURN p_cursor_name;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_get_available_rooms_by_type: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calculate_guest_discount(
    p_guest_id INT,
    p_booking_price NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
    v_base_discount NUMERIC := 0.00;
    v_comp_discount NUMERIC := 0.00;
    v_total_discount NUMERIC := 0.00;
    v_guest_exists INT;
    
    -- Explicit cursor to check guest's feedback history
    cur_feedbacks CURSOR FOR
        SELECT gf.rating 
        FROM GUEST_FEEDBACK gf
        JOIN STAY_RECORD sr ON gf.stay_id = sr.stay_id
        WHERE sr.guest_id = p_guest_id;
        
    r_feedback RECORD;
BEGIN
    -- Validate guest existence
    SELECT 1 INTO v_guest_exists FROM GUESTS WHERE guest_id = p_guest_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Guest with ID % does not exist.', p_guest_id;
    END IF;

    -- Retrieve loyalty tier discount (Implicit query)
    SELECT lt.discount_percentage INTO v_base_discount
    FROM GUEST_LOYALTY gl
    JOIN LOYALTY_TIER lt ON gl.tier_id = lt.tier_id
    WHERE gl.guest_id = p_guest_id AND gl.status = 'ACTIVE';

    -- If no active loyalty membership, base discount is 0
    IF v_base_discount IS NULL THEN
        v_base_discount := 0.00;
    END IF;

    -- Open explicit cursor and loop through feedback ratings
    OPEN cur_feedbacks;
    LOOP
        FETCH cur_feedbacks INTO r_feedback;
        EXIT WHEN NOT FOUND;
        
        -- If guest had a stay with poor feedback (rating <= 2), apply 10% compensation
        IF r_feedback.rating <= 2 THEN
            v_comp_discount := 10.00;
        END IF;
    END LOOP;
    CLOSE cur_feedbacks;

    -- Calculate total discount
    v_total_discount := v_base_discount + v_comp_discount;
    
    -- Limit total discount to 50% max
    IF v_total_discount > 50.00 THEN
        v_total_discount := 50.00;
    END IF;

    -- Return the final discounted price
    RETURN ROUND(p_booking_price * (1 - v_total_discount / 100), 2);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_calculate_guest_discount: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;

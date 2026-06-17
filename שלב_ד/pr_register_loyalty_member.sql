CREATE OR REPLACE PROCEDURE pr_register_loyalty_member(
    p_guest_id INT
)
AS $$
DECLARE
    v_total_spent NUMERIC := 0.00;
    v_tier_id INT;
    v_membership_num VARCHAR(20);
    v_guest_exists INT;
    v_loyalty_exists INT;
BEGIN
    -- Validate guest existence
    SELECT 1 INTO v_guest_exists FROM GUESTS WHERE guest_id = p_guest_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Guest with ID % does not exist.', p_guest_id;
    END IF;

    -- Calculate total spent on completed payments (Implicit Cursor)
    SELECT COALESCE(SUM(p.amount), 0.00) INTO v_total_spent
    FROM PAYMENT p
    JOIN STAY_RECORD sr ON p.stay_id = sr.stay_id
    WHERE sr.guest_id = p_guest_id AND p.payment_status = 'COMPLETED';

    -- Determine loyalty tier based on total spent
    IF v_total_spent >= 5000.00 THEN
        v_tier_id := 4; -- Platinum
    ELSIF v_total_spent >= 1500.00 THEN
        v_tier_id := 3; -- Gold
    ELSIF v_total_spent >= 500.00 THEN
        v_tier_id := 2; -- Silver
    ELSE
        v_tier_id := 1; -- Bronze
    END IF;

    -- Check if guest is already a loyalty member
    SELECT 1 INTO v_loyalty_exists FROM GUEST_LOYALTY WHERE guest_id = p_guest_id;
    
    IF FOUND THEN
        -- Upgrade or update membership
        UPDATE GUEST_LOYALTY 
        SET tier_id = v_tier_id
        WHERE guest_id = p_guest_id;
        RAISE NOTICE 'Updated loyalty membership for guest %. New Tier ID: %.', p_guest_id, v_tier_id;
    ELSE
        -- Generate membership number
        v_membership_num := 'MEM-' || (10000 + p_guest_id);
        
        -- Insert new membership (DML)
        INSERT INTO GUEST_LOYALTY (guest_id, tier_id, membership_number, points_balance, status)
        VALUES (p_guest_id, v_tier_id, v_membership_num, CAST(v_total_spent / 10 AS INT), 'ACTIVE');
        RAISE NOTICE 'Registered new loyalty membership for guest %. Membership: %, Tier ID: %.', p_guest_id, v_membership_num, v_tier_id;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Failed to register/upgrade loyalty member (ID: %): %', p_guest_id, SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;

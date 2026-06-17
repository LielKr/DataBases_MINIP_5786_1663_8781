-- =========================================================
-- trg_update_loyalty_points.sql - שלב ד: טריגר נקודות נאמנות
-- מעדכן נקודות נאמנות ומשדרג דרגה באופן אוטומטי בעת ביצוע תשלום
-- =========================================================

CREATE OR REPLACE FUNCTION fn_trg_update_loyalty_points()
RETURNS TRIGGER AS $$
DECLARE
    v_guest_id INT;
    v_points_to_add INT;
    v_new_points INT;
    v_new_tier_id INT;
    v_loyalty_exists INT;
BEGIN
    -- Only trigger when payment changes to 'COMPLETED'
    IF NEW.payment_status = 'COMPLETED' AND (OLD.payment_status IS NULL OR OLD.payment_status != 'COMPLETED') THEN
        -- Find guest_id related to the stay
        SELECT guest_id INTO v_guest_id FROM STAY_RECORD WHERE stay_id = NEW.stay_id;
        
        IF FOUND THEN
            -- Check if guest has a loyalty membership
            SELECT 1 INTO v_loyalty_exists FROM GUEST_LOYALTY WHERE guest_id = v_guest_id;
            
            IF FOUND THEN
                -- Calculate points: 1 point for every 10 units spent
                v_points_to_add := CAST(NEW.amount / 10 AS INT);
                
                -- Update points balance
                UPDATE GUEST_LOYALTY
                SET points_balance = points_balance + v_points_to_add
                WHERE guest_id = v_guest_id
                RETURNING points_balance INTO v_new_points;
                
                -- Determine new tier based on new points balance
                IF v_new_points >= 5000 THEN
                    v_new_tier_id := 4; -- Platinum
                ELSIF v_new_points >= 1500 THEN
                    v_new_tier_id := 3; -- Gold
                ELSIF v_new_points >= 500 THEN
                    v_new_tier_id := 2; -- Silver
                ELSE
                    v_new_tier_id := 1; -- Bronze
                END IF;
                
                -- Update tier if upgraded
                UPDATE GUEST_LOYALTY
                SET tier_id = v_new_tier_id
                WHERE guest_id = v_guest_id;
                
                RAISE NOTICE 'Trigger: Guest % received % points. New balance: %. Tier set to %.', v_guest_id, v_points_to_add, v_new_points, v_new_tier_id;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Trigger error fn_trg_update_loyalty_points: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_loyalty_points ON PAYMENT;

CREATE TRIGGER trg_update_loyalty_points
AFTER UPDATE OF payment_status ON PAYMENT
FOR EACH ROW
EXECUTE FUNCTION fn_trg_update_loyalty_points();

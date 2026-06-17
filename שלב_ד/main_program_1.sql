-- =========================================================
-- main_program_1.sql - שלב ד: תוכנית ראשית 1
-- מזמנת את פונקציית החיוב ומריצה את פרוצדורת מועדון הלקוחות
-- =========================================================

DO $$
DECLARE
    v_guest_id INT := 1; -- יוסי כהן (אורח קיים)
    v_original_price NUMERIC := 1200.00;
    v_discounted_price NUMERIC;
    v_tier_name VARCHAR(50);
BEGIN
    RAISE NOTICE '=== Running Main Program 1 ===';
    
    -- 1. זימון פונקציה לחישוב ההנחה
    v_discounted_price := fn_calculate_guest_discount(v_guest_id, v_original_price);
    
    RAISE NOTICE 'Guest ID: %', v_guest_id;
    RAISE NOTICE 'Original Price: %', v_original_price;
    RAISE NOTICE 'Discounted Price: %', v_discounted_price;
    
    -- 2. זימון פרוצדורה לבדיקה ושדרוג מועדון נאמנות
    RAISE NOTICE 'Evaluating loyalty membership...';
    CALL pr_register_loyalty_member(v_guest_id);
    
    -- 3. שליפת התוצאה המעודכנת לצורך אימות
    SELECT lt.tier_name INTO v_tier_name
    FROM GUEST_LOYALTY gl
    JOIN LOYALTY_TIER lt ON gl.tier_id = lt.tier_id
    WHERE gl.guest_id = v_guest_id;
    
    RAISE NOTICE 'Current Loyalty Tier in Database: %', v_tier_name;
    RAISE NOTICE '==============================';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Exception caught in Main Program 1: %', SQLERRM;
END;
$$;

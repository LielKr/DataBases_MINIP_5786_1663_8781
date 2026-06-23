-- =============================================
-- Integrate.sql - שלב ג: אינטגרציה
-- שינוי טבלאות קיימות ויצירת טבלאות חדשות
-- =============================================

-- =============================================
-- חלק 1: שינוי טבלאות קיימות (ALTER TABLE)
-- =============================================

-- הוספת עמודת created_at לטבלת GUESTS
-- החלטת אינטגרציה: משאירים first_name, last_name, passport_number ב-GUESTS
-- כדי שהשאילתות מהשלב הקודם ימשיכו לעבוד.
-- PRIVATE_GUEST מוסיפה שדות נוספים (gender, id_or_passport_number) ומאפשרת
-- להבחין בין אורח פרטי לעסקי.

ALTER TABLE GUESTS ADD COLUMN created_at DATE;

UPDATE GUESTS SET created_at = registration_date WHERE created_at IS NULL;

-- =============================================
-- חלק 2: יצירת טבלאות חדשות (מהאגף שקיבלנו)
-- =============================================

-- טבלת PRIVATE_GUEST - ירושה מ-GUESTS (אורח פרטי)
-- מכילה שדות נוספים מעבר למה שכבר קיים ב-GUESTS
CREATE TABLE PRIVATE_GUEST
(
  guest_id              INT          NOT NULL,
  first_name            VARCHAR(50)  NOT NULL,
  last_name             VARCHAR(50)  NOT NULL,
  id_or_passport_number VARCHAR(20)  NOT NULL,
  gender                VARCHAR(10),

  PRIMARY KEY (guest_id),

  FOREIGN KEY (guest_id)
    REFERENCES GUESTS(guest_id),

  CONSTRAINT uq_private_passport
    UNIQUE (id_or_passport_number),

  CONSTRAINT chk_gender
    CHECK (gender IN ('MALE', 'FEMALE', 'OTHER'))
);

-- טבלת CORPORATE_GUEST - ירושה מ-GUESTS (אורח עסקי)
CREATE TABLE CORPORATE_GUEST
(
  guest_id                    INT           NOT NULL,
  company_name                VARCHAR(100)  NOT NULL,
  company_registration_number VARCHAR(50)   NOT NULL,
  contact_person_name         VARCHAR(100)  NOT NULL,

  PRIMARY KEY (guest_id),

  FOREIGN KEY (guest_id)
    REFERENCES GUESTS(guest_id),

  CONSTRAINT uq_company_reg
    UNIQUE (company_registration_number)
);

-- טבלת LOYALTY_TIER - דרגות נאמנות
CREATE TABLE LOYALTY_TIER
(
  tier_id               INT           NOT NULL,
  tier_name             VARCHAR(50)   NOT NULL,
  points_required       INT           NOT NULL,
  discount_percentage   NUMERIC(5,2)  NOT NULL,
  benefits_description  VARCHAR(300),

  PRIMARY KEY (tier_id),

  CONSTRAINT uq_tier_name
    UNIQUE (tier_name),

  CONSTRAINT chk_points_required
    CHECK (points_required >= 0),

  CONSTRAINT chk_discount
    CHECK (discount_percentage BETWEEN 0 AND 100)
);

-- טבלת GUEST_LOYALTY - מנוי נאמנות לאורח
CREATE TABLE GUEST_LOYALTY
(
  guest_id          INT         NOT NULL,
  tier_id           INT         NOT NULL,
  membership_number VARCHAR(20) NOT NULL,
  points_balance    INT         NOT NULL DEFAULT 0,
  status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

  PRIMARY KEY (guest_id),

  FOREIGN KEY (guest_id)
    REFERENCES GUESTS(guest_id),

  FOREIGN KEY (tier_id)
    REFERENCES LOYALTY_TIER(tier_id),

  CONSTRAINT uq_membership
    UNIQUE (membership_number),

  CONSTRAINT chk_points_balance
    CHECK (points_balance >= 0),

  CONSTRAINT chk_loyalty_status
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);

-- טבלת STAY_RECORD - רשומת שהייה
CREATE TABLE STAY_RECORD
(
  stay_id        INT  NOT NULL,
  check_in_date  DATE NOT NULL,
  check_out_date DATE NOT NULL,
  guest_id       INT  NOT NULL,
  booking_id     INT  NOT NULL,

  PRIMARY KEY (stay_id),

  FOREIGN KEY (guest_id)
    REFERENCES GUESTS(guest_id),

  FOREIGN KEY (booking_id)
    REFERENCES BOOKINGS(booking_id),

  CONSTRAINT chk_stay_dates
    CHECK (check_out_date > check_in_date)
);

-- טבלת PAYMENT - תשלומים על שהייה
CREATE TABLE PAYMENT
(
  payment_id     INT            NOT NULL,
  payment_date   DATE           NOT NULL,
  amount         NUMERIC(10,2)  NOT NULL,
  payment_method VARCHAR(30)    NOT NULL,
  payment_status VARCHAR(20)    NOT NULL,
  stay_id        INT            NOT NULL,

  PRIMARY KEY (payment_id),

  FOREIGN KEY (stay_id)
    REFERENCES STAY_RECORD(stay_id),

  CONSTRAINT chk_payment_amount
    CHECK (amount > 0),

  CONSTRAINT chk_payment_method
    CHECK (payment_method IN ('CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'BANK_TRANSFER', 'CHECK')),

  CONSTRAINT chk_payment_status
    CHECK (payment_status IN ('PENDING', 'COMPLETED', 'REFUNDED', 'FAILED'))
);

-- טבלת GUEST_FEEDBACK - פידבק על שהייה
CREATE TABLE GUEST_FEEDBACK
(
  stay_id       INT          NOT NULL,
  rating        INT          NOT NULL,
  comments      VARCHAR(500),
  feedback_date DATE         NOT NULL,

  PRIMARY KEY (stay_id),

  FOREIGN KEY (stay_id)
    REFERENCES STAY_RECORD(stay_id),

  CONSTRAINT chk_rating
    CHECK (rating BETWEEN 1 AND 5)
);

-- =============================================
-- חלק 3: הכנסת נתונים לטבלאות החדשות
-- =============================================

-- העתקת אורחים קיימים ל-PRIVATE_GUEST (כל האורחים הקיימים הם פרטיים)
INSERT INTO PRIVATE_GUEST (guest_id, first_name, last_name, id_or_passport_number, gender)
SELECT guest_id, first_name, last_name, passport_number, NULL
FROM GUESTS;

-- מחיקת העמודות המיותרות מטבלת GUESTS לאחר העתקתן ל-PRIVATE_GUEST
ALTER TABLE GUESTS DROP COLUMN first_name;
ALTER TABLE GUESTS DROP COLUMN last_name;
ALTER TABLE GUESTS DROP COLUMN passport_number;

-- נתוני אורחים עסקיים (2 אורחים חדשים)
INSERT INTO GUESTS (guest_id, phone, email, registration_date, created_at) VALUES
(51001, '0501111111', 'rachel@techsol.com', '2024-05-01', '2024-05-01'),
(51002, '0502222222', 'daniel@globaltrade.com', '2024-05-10', '2024-05-10');

INSERT INTO CORPORATE_GUEST (guest_id, company_name, company_registration_number, contact_person_name) VALUES
(51001, 'Tech Solutions Ltd', 'CR-2024-001', 'Rachel Cohen'),
(51002, 'Global Trading Inc', 'CR-2024-002', 'Daniel Levi');

-- נתוני דרגות נאמנות
INSERT INTO LOYALTY_TIER (tier_id, tier_name, points_required, discount_percentage, benefits_description) VALUES
(1, 'Bronze',   0,    5.00,  'Basic benefits: early check-in when available'),
(2, 'Silver',   500,  10.00, 'Priority check-in, room upgrade when available'),
(3, 'Gold',     1500, 15.00, 'Free breakfast, late checkout, room upgrade priority'),
(4, 'Platinum', 5000, 25.00, 'All Gold benefits plus free spa access and airport transfer');

-- נתוני נאמנות לאורחים
INSERT INTO GUEST_LOYALTY (guest_id, tier_id, membership_number, points_balance, status) VALUES
(1, 3, 'MEM-10001', 1750, 'ACTIVE'),
(2, 2, 'MEM-10002', 820,  'ACTIVE'),
(3, 1, 'MEM-10003', 200,  'ACTIVE'),
(4, 4, 'MEM-10004', 5500, 'ACTIVE'),
(5, 1, 'MEM-10005', 50,   'ACTIVE');

-- נתוני שהיות (מבוססים על ההזמנות הקיימות)
INSERT INTO STAY_RECORD (stay_id, check_in_date, check_out_date, guest_id, booking_id)
SELECT
  b.booking_id AS stay_id,
  b.check_in_date,
  b.check_out_date,
  b.guest_id,
  b.booking_id
FROM BOOKINGS b;

-- נתוני תשלומים (stay_id מתאים ל-booking_id שקיים ב-stay_record)
INSERT INTO PAYMENT (payment_id, payment_date, amount, payment_method, payment_status, stay_id) VALUES
(1,  '2024-06-05', 500.00,  'CREDIT_CARD',   'COMPLETED', 1001),
(2,  '2024-06-04', 300.00,  'DEBIT_CARD',    'COMPLETED', 1002),
(3,  '2024-06-06', 450.00,  'CREDIT_CARD',   'COMPLETED', 1003),
(4,  '2024-06-07', 600.00,  'BANK_TRANSFER', 'COMPLETED', 1004),
(5,  '2024-06-08', 750.00,  'CREDIT_CARD',   'COMPLETED', 1005),
(6,  '2024-06-09', 400.00,  'CASH',          'COMPLETED', 1006),
(7,  '2024-06-10', 550.00,  'CREDIT_CARD',   'COMPLETED', 1007),
(8,  '2024-06-11', 350.00,  'DEBIT_CARD',    'COMPLETED', 1008),
(9,  '2024-06-12', 480.00,  'CREDIT_CARD',   'COMPLETED', 1009),
(10, '2024-06-13', 620.00,  'BANK_TRANSFER', 'COMPLETED', 1010);

-- נתוני פידבק
INSERT INTO GUEST_FEEDBACK (stay_id, rating, comments, feedback_date) VALUES
(1011,   5, 'Excellent service and clean rooms!', '2024-06-06'),
(1012,   4, 'Good stay, breakfast could be better', '2024-06-05'),
(1001, 3, 'Average experience', '2024-06-07'),
(1002, 5, 'Perfect! Will come back', '2024-06-08'),
(1003, 4, NULL, '2024-06-09'),
(1004, 2, 'Room was not clean upon arrival', '2024-06-10'),
(1005, 5, 'Amazing staff!', '2024-06-11'),
(1006, 4, 'Comfortable bed, nice view', '2024-06-12');

-- הוספת הזמנות לאורחים העסקיים
INSERT INTO BOOKINGS (booking_id, check_in_date, check_out_date, total_price, num_guests, booking_date, guest_id, source_id) VALUES
(50998, '2024-07-01', '2024-07-05', 1200.00, 2, '2024-06-20', 51001, 1),
(50999, '2024-07-10', '2024-07-12', 800.00,  1, '2024-06-25', 51002, 2);

INSERT INTO STAY_RECORD (stay_id, check_in_date, check_out_date, guest_id, booking_id) VALUES
(50998, '2024-07-01', '2024-07-05', 51001, 50998),
(50999, '2024-07-10', '2024-07-12', 51002, 50999);

INSERT INTO PAYMENT (payment_id, payment_date, amount, payment_method, payment_status, stay_id) VALUES
(11, '2024-07-05', 1200.00, 'BANK_TRANSFER', 'COMPLETED', 50998),
(12, '2024-07-12', 800.00,  'CREDIT_CARD',   'COMPLETED', 50999);

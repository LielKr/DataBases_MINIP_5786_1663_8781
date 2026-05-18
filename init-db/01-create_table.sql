CREATE TABLE ROOM_TYPES
(
  type_id       INT            NOT NULL,
  type_name     VARCHAR(50)    NOT NULL,
  base_price    NUMERIC(10,2)  NOT NULL,
  max_occupancy INT            NOT NULL,
  description   VARCHAR(300),

  PRIMARY KEY (type_id),

  CONSTRAINT uq_room_type_name
    UNIQUE (type_name),

  CONSTRAINT chk_base_price
    CHECK (base_price > 0),

  CONSTRAINT chk_max_occupancy
    CHECK (max_occupancy BETWEEN 1 AND 10)
);

CREATE TABLE ROOMS
(
  room_id         INT          NOT NULL,
  floor           INT          NOT NULL,
  physical_status VARCHAR(20)  NOT NULL DEFAULT 'AVAILABLE',
  phone_extension VARCHAR(10),
  type_id         INT          NOT NULL,

  PRIMARY KEY (room_id),

  FOREIGN KEY (type_id)
    REFERENCES ROOM_TYPES(type_id),

  CONSTRAINT chk_room_status
    CHECK (physical_status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'OUT_OF_ORDER')),

  CONSTRAINT chk_floor
    CHECK (floor BETWEEN 1 AND 50),

  CONSTRAINT uq_phone_extension
    UNIQUE (phone_extension)
);

CREATE TABLE BOOKING_SOURCES
(
  source_id       INT           NOT NULL,
  source_name     VARCHAR(100)  NOT NULL,
  commission_rate NUMERIC(5,2)  NOT NULL,
  contact_info    VARCHAR(200),

  PRIMARY KEY (source_id),

  CONSTRAINT uq_source_name
    UNIQUE (source_name),

  CONSTRAINT chk_commission
    CHECK (commission_rate BETWEEN 0 AND 100)
);

CREATE TABLE GUESTS
(
  guest_id          INT           NOT NULL,
  first_name        VARCHAR(50)   NOT NULL,
  last_name         VARCHAR(50)   NOT NULL,
  passport_number   VARCHAR(20)   NOT NULL,
  phone             VARCHAR(20)   NOT NULL,
  email             VARCHAR(100)  NOT NULL,
  registration_date DATE          NOT NULL,

  PRIMARY KEY (guest_id),

  CONSTRAINT uq_guest_passport
    UNIQUE (passport_number),

  CONSTRAINT uq_guest_email
    UNIQUE (email),

  CONSTRAINT chk_email
    CHECK (email LIKE '%@%')
);

CREATE TABLE BOOKINGS
(
  booking_id     INT            NOT NULL,
  check_in_date  DATE           NOT NULL,
  check_out_date DATE           NOT NULL,
  total_price    NUMERIC(10,2)  NOT NULL,
  num_guests     INT            NOT NULL,
  booking_date   DATE           NOT NULL,
  guest_id       INT            NOT NULL,
  source_id      INT            NOT NULL,

  PRIMARY KEY (booking_id),

  FOREIGN KEY (guest_id)
    REFERENCES GUESTS(guest_id),

  FOREIGN KEY (source_id)
    REFERENCES BOOKING_SOURCES(source_id),

  CONSTRAINT chk_booking_dates
    CHECK (check_out_date > check_in_date),

  CONSTRAINT chk_booking_date_before_checkin
    CHECK (booking_date <= check_in_date),

  CONSTRAINT chk_num_guests
    CHECK (num_guests >= 1),

  CONSTRAINT chk_total_price
    CHECK (total_price >= 0)
);

CREATE TABLE ROOM_ASSIGNMENTS
(
  assignment_id INT  NOT NULL,
  assigned_at   DATE NOT NULL,
  booking_id    INT  NOT NULL,
  room_id       INT  NOT NULL,

  PRIMARY KEY (assignment_id),

  FOREIGN KEY (booking_id)
    REFERENCES BOOKINGS(booking_id),

  FOREIGN KEY (room_id)
    REFERENCES ROOMS(room_id),

  CONSTRAINT uq_booking_room
    UNIQUE (booking_id, room_id)
);

CREATE TABLE CHECK_INS_OUTS
(
  log_id           INT  NOT NULL,
  actual_check_in  DATE,
  actual_check_out DATE,
  booking_id       INT  NOT NULL,

  PRIMARY KEY (log_id, booking_id),

  FOREIGN KEY (booking_id)
    REFERENCES BOOKINGS(booking_id),

  CONSTRAINT chk_actual_check_dates
    CHECK (
      actual_check_out IS NULL
      OR actual_check_in IS NULL
      OR actual_check_out >= actual_check_in
    )
);
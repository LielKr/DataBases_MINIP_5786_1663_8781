# generate_data.py
# תלויות: pip install faker
# הרצה:   python generate_data.py
# פלט:    insertTables_python.sql

import random
from datetime import date, timedelta
from faker import Faker

fake = Faker(['he_IL', 'en_US', 'de_DE', 'fr_FR'])
Faker.seed(42)
random.seed(42)

OUTPUT_FILE = "insertTables_python.sql"

# ============================================================
# הגדרות כמויות
# ============================================================
NUM_ROOMS        = 462    # + 38 מהשיטה הידנית = 500 סה"כ
NUM_GUESTS       = 19980  # + 20 מהשיטה הידנית = 20,000 סה"כ
NUM_BOOKINGS     = 19975  # + 25 מהשיטה הידנית = 20,000 סה"כ
NUM_ASSIGNMENTS  = 475    # + 25 מהשיטה הידנית = 500 סה"כ
NUM_CHECKINS     = 485    # + 15 מהשיטה הידנית = 500 סה"כ

# ============================================================
# נתונים קיימים מהשיטה הידנית (נמנע מכפילויות)
# ============================================================
EXISTING_TYPE_IDS   = list(range(1, 8))
EXISTING_SOURCE_IDS = list(range(1, 8))
EXISTING_ROOM_IDS   = {
    101,102,103,104,105,106,
    201,202,203,204,205,206,
    301,302,303,304,305,
    401,402,403,404,405,
    501,502,503,504,
    601,602,603,604,
    701,702,703,704,
    801,802,803,804
}
EXISTING_GUEST_IDS        = set(range(1, 21))
EXISTING_BOOKING_IDS      = set(range(1001, 1026))
EXISTING_ASSIGN_IDS       = set(range(1, 26))
EXISTING_CHECKIN_IDS      = set(range(1, 16))
EXISTING_CHECKIN_BOOKINGS = set(range(1001, 1016))


# ============================================================
# פונקציות עזר
# ============================================================
def random_date(start: date, end: date) -> date:
    return start + timedelta(days=random.randint(0, (end - start).days))

def write_section(f, title: str):
    f.write(f"\n-- {'='*60}\n")
    f.write(f"-- {title}\n")
    f.write(f"-- {'='*60}\n\n")

def flush_rows(f, sql_header: str, rows: list):
    if rows:
        f.write(sql_header + "\n")
        f.write(",\n".join(rows) + ";\n\n")


# ============================================================
# יצירת הקובץ
# ============================================================
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:

    f.write("-- insertTables_python.sql\n")
    f.write("-- נוצר אוטומטית על ידי generate_data.py\n")
    f.write(f"-- תאריך יצירה: {date.today()}\n\n")

    # ----------------------------------------------------------
    # ROOMS – 462 רשומות
    # ----------------------------------------------------------
    write_section(f, "ROOMS")

    statuses     = ['AVAILABLE', 'AVAILABLE', 'AVAILABLE', 'OCCUPIED', 'MAINTENANCE']
    room_id      = 1000
    all_room_ids = list(EXISTING_ROOM_IDS)
    rows         = []

    for _ in range(NUM_ROOMS):
        while room_id in EXISTING_ROOM_IDS:
            room_id += 1
        floor  = random.randint(1, 15)
        status = random.choice(statuses)
        t_id   = random.choice(EXISTING_TYPE_IDS)
        rows.append(f"({room_id}, {floor}, '{status}', '{room_id}', {t_id})")
        all_room_ids.append(room_id)
        room_id += 1

    flush_rows(f,
        "INSERT INTO ROOMS (room_id, floor, physical_status, phone_extension, type_id) VALUES",
        rows)

    # ----------------------------------------------------------
    # GUESTS – 19,980 רשומות (בחבילות של 500)
    # ----------------------------------------------------------
    write_section(f, "GUESTS")

    GUEST_SQL      = "INSERT INTO GUESTS (guest_id, first_name, last_name, passport_number, phone, email, registration_date) VALUES"
    guest_id       = 1000
    all_guest_ids  = list(EXISTING_GUEST_IDS)
    used_passports = set()
    used_emails    = set()
    rows           = []
    count          = 0

    while count < NUM_GUESTS:
        while guest_id in EXISTING_GUEST_IDS:
            guest_id += 1

        first    = fake.first_name().replace("'", "''")
        last     = fake.last_name().replace("'", "''")
        passport = f"P{random.randint(10000000, 99999999)}"

        if passport in used_passports:
            guest_id += 1
            continue
        used_passports.add(passport)

        email = f"{fake.user_name()}_{guest_id}@{random.choice(['gmail.com','yahoo.com','outlook.com','walla.co.il'])}"
        if email in used_emails:
            guest_id += 1
            continue
        used_emails.add(email)

        phone    = f"05{random.randint(0,9)}-{random.randint(1000000,9999999)}"
        reg_date = random_date(date(2020, 1, 1), date(2024, 12, 31))

        rows.append(
            f"({guest_id}, '{first}', '{last}', '{passport}', '{phone}', '{email}', '{reg_date}')"
        )
        all_guest_ids.append(guest_id)
        guest_id += 1
        count    += 1

        if len(rows) == 500:
            flush_rows(f, GUEST_SQL, rows)
            rows = []

    flush_rows(f, GUEST_SQL, rows)

    # ----------------------------------------------------------
    # BOOKINGS – 19,975 רשומות (בחבילות של 500)
    # ----------------------------------------------------------
    write_section(f, "BOOKINGS")

    BOOKING_SQL     = "INSERT INTO BOOKINGS (booking_id, booking_date, check_in_date, check_out_date, num_guests, total_price, guest_id, source_id) VALUES"
    booking_id      = 2000
    all_booking_ids = list(EXISTING_BOOKING_IDS)
    rows            = []
    count           = 0

    while count < NUM_BOOKINGS:
        while booking_id in EXISTING_BOOKING_IDS:
            booking_id += 1

        g_id       = random.choice(all_guest_ids)
        s_id       = random.choice(EXISTING_SOURCE_IDS)
        check_in   = random_date(date(2022, 1, 1), date(2025, 6, 30))
        nights     = random.randint(1, 14)
        check_out  = check_in + timedelta(days=nights)
        book_date  = check_in - timedelta(days=random.randint(1, 90))
        n_guests   = random.randint(1, 4)
        price      = random.choice([350, 480, 500, 750, 900, 1200, 2000])
        total      = round(price * nights, 2)

        rows.append(
            f"({booking_id}, '{book_date}', '{check_in}', '{check_out}', {n_guests}, {total}, {g_id}, {s_id})"
        )
        all_booking_ids.append(booking_id)
        booking_id += 1
        count      += 1

        if len(rows) == 500:
            flush_rows(f, BOOKING_SQL, rows)
            rows = []

    flush_rows(f, BOOKING_SQL, rows)

    # ----------------------------------------------------------
    # ROOM_ASSIGNMENTS – 475 רשומות
    # ----------------------------------------------------------
    write_section(f, "ROOM_ASSIGNMENTS")

    assign_id  = 500
    used_pairs = set()
    rows       = []
    count      = 0
    attempts   = 0

    while count < NUM_ASSIGNMENTS and attempts < NUM_ASSIGNMENTS * 20:
        attempts += 1
        while assign_id in EXISTING_ASSIGN_IDS:
            assign_id += 1

        b_id = random.choice(all_booking_ids)
        r_id = random.choice(all_room_ids)
        pair = (b_id, r_id)

        if pair in used_pairs:
            continue
        used_pairs.add(pair)

        assigned_at = random_date(date(2022, 1, 1), date(2025, 6, 30))
        rows.append(f"({assign_id}, '{assigned_at}', {b_id}, {r_id})")
        assign_id += 1
        count     += 1

    flush_rows(f,
        "INSERT INTO ROOM_ASSIGNMENTS (assignment_id, assigned_at, booking_id, room_id) VALUES",
        rows)

    # ----------------------------------------------------------
    # CHECK_INS_OUTS – 485 רשומות
    # ----------------------------------------------------------
    write_section(f, "CHECK_INS_OUTS")

    checkin_id = 500
    available  = [b for b in all_booking_ids if b not in EXISTING_CHECKIN_BOOKINGS]
    sample     = random.sample(available, min(NUM_CHECKINS, len(available)))
    rows       = []

    for b_id in sample:
        while checkin_id in EXISTING_CHECKIN_IDS:
            checkin_id += 1
        check_in  = random_date(date(2022, 1, 1), date(2025, 6, 30))
        check_out = check_in + timedelta(days=random.randint(1, 14))
        rows.append(f"({checkin_id}, '{check_in}', '{check_out}', {b_id})")
        checkin_id += 1

    flush_rows(f,
        "INSERT INTO CHECK_INS_OUTS (log_id, actual_check_in, actual_check_out, booking_id) VALUES",
        rows)


print(f"\n✓ הקובץ '{OUTPUT_FILE}' נוצר בהצלחה!\n")
print(f"  ROOMS:            {NUM_ROOMS:>6,} רשומות")
print(f"  GUESTS:           {NUM_GUESTS:>6,} רשומות")
print(f"  BOOKINGS:         {NUM_BOOKINGS:>6,} רשומות")
print(f"  ROOM_ASSIGNMENTS: {NUM_ASSIGNMENTS:>6,} רשומות")
print(f"  CHECK_INS_OUTS:   {NUM_CHECKINS:>6,} רשומות")

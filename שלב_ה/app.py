import os
import psycopg2
import psycopg2.extras
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

app = Flask(__name__)
app.secret_key = 'hotel-management-secret-key-5786'

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'dbname': os.getenv('DB_NAME_SECRET', 'hotel'),
    'user': os.getenv('DB_USER_SECRET', 'Myuser'),
    'password': os.getenv('DB_PASSWORD_SECRET', 'pass1234'),
}


def get_db():
    return psycopg2.connect(**DB_CONFIG)


def query_db(sql, params=None, fetchone=False):
    conn = get_db()
    conn.autocommit = True
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, params)
            if cur.description:
                return cur.fetchone() if fetchone else cur.fetchall()
            return None
    finally:
        conn.close()


def execute_db(sql, params=None):
    conn = get_db()
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.rowcount
    finally:
        conn.close()


# ──────────────────────────────────────────────
# Home / Dashboard
# ──────────────────────────────────────────────
@app.route('/')
def index():
    stats = {}
    stats['total_rooms'] = query_db("SELECT COUNT(*) AS c FROM rooms", fetchone=True)['c']
    stats['total_guests'] = query_db("SELECT COUNT(*) AS c FROM guests", fetchone=True)['c']
    stats['total_bookings'] = query_db("SELECT COUNT(*) AS c FROM bookings", fetchone=True)['c']
    stats['confirmed'] = query_db(
        "SELECT COUNT(*) AS c FROM bookings WHERE booking_status='CONFIRMED'", fetchone=True)['c']
    stats['available_rooms'] = query_db(
        "SELECT COUNT(*) AS c FROM rooms WHERE physical_status='AVAILABLE'", fetchone=True)['c']
    return render_template('index.html', stats=stats)


# ──────────────────────────────────────────────
# ROOM TYPES  (CRUD)
# ──────────────────────────────────────────────
@app.route('/room_types')
def room_types_list():
    rows = query_db("SELECT * FROM room_types ORDER BY type_id")
    return render_template('room_types.html', rows=rows)


@app.route('/room_types/add', methods=['GET', 'POST'])
def room_types_add():
    if request.method == 'POST':
        try:
            execute_db(
                "INSERT INTO room_types (type_id, type_name, base_price, max_occupancy, description) "
                "VALUES (%s,%s,%s,%s,%s)",
                (request.form['type_id'], request.form['type_name'],
                 request.form['base_price'], request.form['max_occupancy'],
                 request.form.get('description', '')))
            flash('Room type added successfully!', 'success')
            return redirect(url_for('room_types_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('room_types_form.html', row=None)


@app.route('/room_types/edit/<int:id>', methods=['GET', 'POST'])
def room_types_edit(id):
    if request.method == 'POST':
        try:
            execute_db(
                "UPDATE room_types SET type_name=%s, base_price=%s, max_occupancy=%s, description=%s "
                "WHERE type_id=%s",
                (request.form['type_name'], request.form['base_price'],
                 request.form['max_occupancy'], request.form.get('description', ''), id))
            flash('Room type updated!', 'success')
            return redirect(url_for('room_types_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    row = query_db("SELECT * FROM room_types WHERE type_id=%s", (id,), fetchone=True)
    return render_template('room_types_form.html', row=row)


@app.route('/room_types/delete/<int:id>', methods=['POST'])
def room_types_delete(id):
    try:
        execute_db("DELETE FROM room_types WHERE type_id=%s", (id,))
        flash('Room type deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('room_types_list'))


# ──────────────────────────────────────────────
# ROOMS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/rooms')
def rooms_list():
    rows = query_db("""
        SELECT r.room_id, r.floor, r.physical_status, r.phone_extension,
               rt.type_name
        FROM rooms r
        JOIN room_types rt ON r.type_id = rt.type_id
        ORDER BY r.room_id
    """)
    return render_template('rooms.html', rows=rows)


@app.route('/rooms/add', methods=['GET', 'POST'])
def rooms_add():
    types = query_db("SELECT type_id, type_name FROM room_types ORDER BY type_name")
    if request.method == 'POST':
        try:
            execute_db(
                "INSERT INTO rooms (room_id, floor, physical_status, phone_extension, type_id) "
                "VALUES (%s,%s,%s,%s,%s)",
                (request.form['room_id'], request.form['floor'],
                 request.form['physical_status'], request.form.get('phone_extension') or None,
                 request.form['type_id']))
            flash('Room added successfully!', 'success')
            return redirect(url_for('rooms_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('rooms_form.html', row=None, types=types)


@app.route('/rooms/edit/<int:id>', methods=['GET', 'POST'])
def rooms_edit(id):
    types = query_db("SELECT type_id, type_name FROM room_types ORDER BY type_name")
    if request.method == 'POST':
        try:
            execute_db(
                "UPDATE rooms SET floor=%s, physical_status=%s, phone_extension=%s, type_id=%s "
                "WHERE room_id=%s",
                (request.form['floor'], request.form['physical_status'],
                 request.form.get('phone_extension') or None, request.form['type_id'], id))
            flash('Room updated!', 'success')
            return redirect(url_for('rooms_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    row = query_db("SELECT * FROM rooms WHERE room_id=%s", (id,), fetchone=True)
    return render_template('rooms_form.html', row=row, types=types)


@app.route('/rooms/delete/<int:id>', methods=['POST'])
def rooms_delete(id):
    try:
        execute_db("DELETE FROM rooms WHERE room_id=%s", (id,))
        flash('Room deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('rooms_list'))


# ──────────────────────────────────────────────
# GUESTS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/guests')
def guests_list():
    rows = query_db("""
        SELECT g.guest_id, g.first_name, g.last_name, g.passport_number,
               g.phone, g.email, g.registration_date,
               lt.tier_name AS loyalty_tier
        FROM guests g
        LEFT JOIN guest_loyalty gl ON g.guest_id = gl.guest_id
        LEFT JOIN loyalty_tier lt ON gl.tier_id = lt.tier_id
        ORDER BY g.guest_id
    """)
    return render_template('guests.html', rows=rows)


@app.route('/guests/add', methods=['GET', 'POST'])
def guests_add():
    if request.method == 'POST':
        try:
            new_id = query_db("SELECT COALESCE(MAX(guest_id),0)+1 AS nid FROM guests", fetchone=True)['nid']
            execute_db(
                "INSERT INTO guests (guest_id, first_name, last_name, passport_number, phone, email, registration_date, created_at) "
                "VALUES (%s,%s,%s,%s,%s,%s, CURRENT_DATE, CURRENT_DATE)",
                (new_id, request.form['first_name'], request.form['last_name'],
                 request.form['passport_number'], request.form['phone'], request.form['email']))
            flash('Guest added successfully!', 'success')
            return redirect(url_for('guests_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('guests_form.html', row=None)


@app.route('/guests/edit/<int:id>', methods=['GET', 'POST'])
def guests_edit(id):
    if request.method == 'POST':
        try:
            execute_db(
                "UPDATE guests SET first_name=%s, last_name=%s, passport_number=%s, phone=%s, email=%s "
                "WHERE guest_id=%s",
                (request.form['first_name'], request.form['last_name'],
                 request.form['passport_number'], request.form['phone'],
                 request.form['email'], id))
            flash('Guest updated!', 'success')
            return redirect(url_for('guests_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    row = query_db("SELECT * FROM guests WHERE guest_id=%s", (id,), fetchone=True)
    return render_template('guests_form.html', row=row)


@app.route('/guests/delete/<int:id>', methods=['POST'])
def guests_delete(id):
    try:
        execute_db("DELETE FROM guests WHERE guest_id=%s", (id,))
        flash('Guest deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('guests_list'))


# ──────────────────────────────────────────────
# BOOKING SOURCES  (CRUD)
# ──────────────────────────────────────────────
@app.route('/booking_sources')
def booking_sources_list():
    rows = query_db("SELECT * FROM booking_sources ORDER BY source_id")
    return render_template('booking_sources.html', rows=rows)


@app.route('/booking_sources/add', methods=['GET', 'POST'])
def booking_sources_add():
    if request.method == 'POST':
        try:
            execute_db(
                "INSERT INTO booking_sources (source_id, source_name, commission_rate, contact_info) "
                "VALUES (%s,%s,%s,%s)",
                (request.form['source_id'], request.form['source_name'],
                 request.form['commission_rate'], request.form.get('contact_info', '')))
            flash('Booking source added!', 'success')
            return redirect(url_for('booking_sources_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('booking_sources_form.html', row=None)


@app.route('/booking_sources/edit/<int:id>', methods=['GET', 'POST'])
def booking_sources_edit(id):
    if request.method == 'POST':
        try:
            execute_db(
                "UPDATE booking_sources SET source_name=%s, commission_rate=%s, contact_info=%s "
                "WHERE source_id=%s",
                (request.form['source_name'], request.form['commission_rate'],
                 request.form.get('contact_info', ''), id))
            flash('Booking source updated!', 'success')
            return redirect(url_for('booking_sources_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    row = query_db("SELECT * FROM booking_sources WHERE source_id=%s", (id,), fetchone=True)
    return render_template('booking_sources_form.html', row=row)


@app.route('/booking_sources/delete/<int:id>', methods=['POST'])
def booking_sources_delete(id):
    try:
        execute_db("DELETE FROM booking_sources WHERE source_id=%s", (id,))
        flash('Booking source deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('booking_sources_list'))


# ──────────────────────────────────────────────
# BOOKINGS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/bookings')
def bookings_list():
    rows = query_db("""
        SELECT b.booking_id, b.check_in_date, b.check_out_date, b.total_price,
               b.num_guests, b.booking_date, b.booking_status,
               g.first_name || ' ' || g.last_name AS guest_name,
               bs.source_name
        FROM bookings b
        JOIN guests g ON b.guest_id = g.guest_id
        JOIN booking_sources bs ON b.source_id = bs.source_id
        ORDER BY b.booking_id DESC
    """)
    return render_template('bookings.html', rows=rows)


@app.route('/bookings/add', methods=['GET', 'POST'])
def bookings_add():
    guests = query_db("SELECT guest_id, first_name || ' ' || last_name AS name FROM guests ORDER BY last_name")
    sources = query_db("SELECT source_id, source_name FROM booking_sources ORDER BY source_name")
    if request.method == 'POST':
        try:
            new_id = query_db("SELECT COALESCE(MAX(booking_id),0)+1 AS nid FROM bookings", fetchone=True)['nid']
            execute_db(
                "INSERT INTO bookings (booking_id, check_in_date, check_out_date, total_price, num_guests, booking_date, guest_id, source_id) "
                "VALUES (%s,%s,%s,%s,%s,CURRENT_DATE,%s,%s)",
                (new_id, request.form['check_in_date'], request.form['check_out_date'],
                 request.form['total_price'], request.form['num_guests'],
                 request.form['guest_id'], request.form['source_id']))
            flash('Booking created!', 'success')
            return redirect(url_for('bookings_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('bookings_form.html', row=None, guests=guests, sources=sources)


@app.route('/bookings/edit/<int:id>', methods=['GET', 'POST'])
def bookings_edit(id):
    guests = query_db("SELECT guest_id, first_name || ' ' || last_name AS name FROM guests ORDER BY last_name")
    sources = query_db("SELECT source_id, source_name FROM booking_sources ORDER BY source_name")
    if request.method == 'POST':
        try:
            execute_db(
                "UPDATE bookings SET check_in_date=%s, check_out_date=%s, total_price=%s, "
                "num_guests=%s, guest_id=%s, source_id=%s, booking_status=%s WHERE booking_id=%s",
                (request.form['check_in_date'], request.form['check_out_date'],
                 request.form['total_price'], request.form['num_guests'],
                 request.form['guest_id'], request.form['source_id'],
                 request.form['booking_status'], id))
            flash('Booking updated!', 'success')
            return redirect(url_for('bookings_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    row = query_db("SELECT * FROM bookings WHERE booking_id=%s", (id,), fetchone=True)
    return render_template('bookings_form.html', row=row, guests=guests, sources=sources)


@app.route('/bookings/delete/<int:id>', methods=['POST'])
def bookings_delete(id):
    try:
        execute_db("DELETE FROM check_ins_outs WHERE booking_id=%s", (id,))
        execute_db("DELETE FROM room_assignments WHERE booking_id=%s", (id,))
        execute_db("DELETE FROM bookings WHERE booking_id=%s", (id,))
        flash('Booking deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('bookings_list'))


# ──────────────────────────────────────────────
# ROOM ASSIGNMENTS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/room_assignments')
def room_assignments_list():
    rows = query_db("""
        SELECT ra.assignment_id, ra.assigned_at,
               ra.booking_id,
               g.first_name || ' ' || g.last_name AS guest_name,
               r.room_id, rt.type_name, r.floor
        FROM room_assignments ra
        JOIN bookings b ON ra.booking_id = b.booking_id
        JOIN guests g ON b.guest_id = g.guest_id
        JOIN rooms r ON ra.room_id = r.room_id
        JOIN room_types rt ON r.type_id = rt.type_id
        ORDER BY ra.assignment_id DESC
    """)
    return render_template('room_assignments.html', rows=rows)


@app.route('/room_assignments/add', methods=['GET', 'POST'])
def room_assignments_add():
    bookings = query_db("""
        SELECT b.booking_id, g.first_name || ' ' || g.last_name || ' (' || b.check_in_date || ')' AS label
        FROM bookings b JOIN guests g ON b.guest_id = g.guest_id
        ORDER BY b.booking_id DESC
    """)
    rooms = query_db("""
        SELECT r.room_id, 'Room ' || r.room_id || ' - ' || rt.type_name || ' (Floor ' || r.floor || ')' AS label
        FROM rooms r JOIN room_types rt ON r.type_id = rt.type_id
        ORDER BY r.room_id
    """)
    if request.method == 'POST':
        try:
            new_id = query_db("SELECT COALESCE(MAX(assignment_id),0)+1 AS nid FROM room_assignments", fetchone=True)['nid']
            execute_db(
                "INSERT INTO room_assignments (assignment_id, assigned_at, booking_id, room_id) "
                "VALUES (%s, CURRENT_DATE, %s, %s)",
                (new_id, request.form['booking_id'], request.form['room_id']))
            flash('Room assigned!', 'success')
            return redirect(url_for('room_assignments_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('room_assignments_form.html', row=None, bookings=bookings, rooms=rooms)


@app.route('/room_assignments/delete/<int:id>', methods=['POST'])
def room_assignments_delete(id):
    try:
        execute_db("DELETE FROM room_assignments WHERE assignment_id=%s", (id,))
        flash('Assignment deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('room_assignments_list'))


# ──────────────────────────────────────────────
# CHECK INS / OUTS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/checkins')
def checkins_list():
    rows = query_db("""
        SELECT cio.log_id, cio.booking_id, cio.actual_check_in, cio.actual_check_out,
               g.first_name || ' ' || g.last_name AS guest_name,
               b.check_in_date AS planned_in, b.check_out_date AS planned_out
        FROM check_ins_outs cio
        JOIN bookings b ON cio.booking_id = b.booking_id
        JOIN guests g ON b.guest_id = g.guest_id
        ORDER BY cio.log_id DESC
    """)
    return render_template('checkins.html', rows=rows)


@app.route('/checkins/add', methods=['GET', 'POST'])
def checkins_add():
    bookings = query_db("""
        SELECT b.booking_id, g.first_name || ' ' || g.last_name || ' (' || b.check_in_date || ')' AS label
        FROM bookings b JOIN guests g ON b.guest_id = g.guest_id
        WHERE b.booking_status = 'CONFIRMED'
        ORDER BY b.booking_id DESC
    """)
    if request.method == 'POST':
        try:
            new_id = query_db("SELECT COALESCE(MAX(log_id),0)+1 AS nid FROM check_ins_outs", fetchone=True)['nid']
            execute_db(
                "INSERT INTO check_ins_outs (log_id, actual_check_in, actual_check_out, booking_id) "
                "VALUES (%s, %s, %s, %s)",
                (new_id,
                 request.form.get('actual_check_in') or None,
                 request.form.get('actual_check_out') or None,
                 request.form['booking_id']))
            flash('Check-in/out recorded!', 'success')
            return redirect(url_for('checkins_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('checkins_form.html', row=None, bookings=bookings)


@app.route('/checkins/delete/<int:log_id>/<int:booking_id>', methods=['POST'])
def checkins_delete(log_id, booking_id):
    try:
        execute_db("DELETE FROM check_ins_outs WHERE log_id=%s AND booking_id=%s", (log_id, booking_id))
        flash('Record deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('checkins_list'))


# ──────────────────────────────────────────────
# LOYALTY TIERS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/loyalty_tiers')
def loyalty_tiers_list():
    rows = query_db("SELECT * FROM loyalty_tier ORDER BY tier_id")
    return render_template('loyalty_tiers.html', rows=rows)


@app.route('/loyalty_tiers/add', methods=['GET', 'POST'])
def loyalty_tiers_add():
    if request.method == 'POST':
        try:
            execute_db(
                "INSERT INTO loyalty_tier (tier_id, tier_name, points_required, discount_percentage, benefits_description) "
                "VALUES (%s,%s,%s,%s,%s)",
                (request.form['tier_id'], request.form['tier_name'],
                 request.form['points_required'], request.form['discount_percentage'],
                 request.form.get('benefits_description', '')))
            flash('Loyalty tier added!', 'success')
            return redirect(url_for('loyalty_tiers_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('loyalty_tiers_form.html', row=None)


@app.route('/loyalty_tiers/edit/<int:id>', methods=['GET', 'POST'])
def loyalty_tiers_edit(id):
    if request.method == 'POST':
        try:
            execute_db(
                "UPDATE loyalty_tier SET tier_name=%s, points_required=%s, discount_percentage=%s, benefits_description=%s "
                "WHERE tier_id=%s",
                (request.form['tier_name'], request.form['points_required'],
                 request.form['discount_percentage'], request.form.get('benefits_description', ''), id))
            flash('Loyalty tier updated!', 'success')
            return redirect(url_for('loyalty_tiers_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    row = query_db("SELECT * FROM loyalty_tier WHERE tier_id=%s", (id,), fetchone=True)
    return render_template('loyalty_tiers_form.html', row=row)


@app.route('/loyalty_tiers/delete/<int:id>', methods=['POST'])
def loyalty_tiers_delete(id):
    try:
        execute_db("DELETE FROM loyalty_tier WHERE tier_id=%s", (id,))
        flash('Loyalty tier deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('loyalty_tiers_list'))


# ──────────────────────────────────────────────
# GUEST LOYALTY  (CRUD)
# ──────────────────────────────────────────────
@app.route('/guest_loyalty')
def guest_loyalty_list():
    rows = query_db("""
        SELECT gl.guest_id, g.first_name || ' ' || g.last_name AS guest_name,
               lt.tier_name, gl.membership_number, gl.points_balance, gl.status
        FROM guest_loyalty gl
        JOIN guests g ON gl.guest_id = g.guest_id
        JOIN loyalty_tier lt ON gl.tier_id = lt.tier_id
        ORDER BY gl.guest_id
    """)
    return render_template('guest_loyalty.html', rows=rows)


@app.route('/guest_loyalty/add', methods=['GET', 'POST'])
def guest_loyalty_add():
    guests = query_db("""
        SELECT g.guest_id, g.first_name || ' ' || g.last_name AS name
        FROM guests g
        WHERE g.guest_id NOT IN (SELECT guest_id FROM guest_loyalty)
        ORDER BY g.last_name
    """)
    tiers = query_db("SELECT tier_id, tier_name FROM loyalty_tier ORDER BY tier_id")
    if request.method == 'POST':
        try:
            execute_db(
                "INSERT INTO guest_loyalty (guest_id, tier_id, membership_number, points_balance, status) "
                "VALUES (%s,%s,%s,%s,%s)",
                (request.form['guest_id'], request.form['tier_id'],
                 request.form['membership_number'], request.form.get('points_balance', 0),
                 request.form.get('status', 'ACTIVE')))
            flash('Loyalty membership added!', 'success')
            return redirect(url_for('guest_loyalty_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('guest_loyalty_form.html', row=None, guests=guests, tiers=tiers)


@app.route('/guest_loyalty/delete/<int:id>', methods=['POST'])
def guest_loyalty_delete(id):
    try:
        execute_db("DELETE FROM guest_loyalty WHERE guest_id=%s", (id,))
        flash('Membership deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('guest_loyalty_list'))


# ──────────────────────────────────────────────
# STAY RECORDS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/stay_records')
def stay_records_list():
    rows = query_db("""
        SELECT sr.stay_id, sr.check_in_date, sr.check_out_date,
               g.first_name || ' ' || g.last_name AS guest_name,
               sr.booking_id
        FROM stay_record sr
        JOIN guests g ON sr.guest_id = g.guest_id
        ORDER BY sr.stay_id DESC
    """)
    return render_template('stay_records.html', rows=rows)


@app.route('/stay_records/add', methods=['GET', 'POST'])
def stay_records_add():
    guests = query_db("SELECT guest_id, first_name || ' ' || last_name AS name FROM guests ORDER BY last_name")
    bookings = query_db("SELECT booking_id FROM bookings ORDER BY booking_id DESC")
    if request.method == 'POST':
        try:
            new_id = query_db("SELECT COALESCE(MAX(stay_id),0)+1 AS nid FROM stay_record", fetchone=True)['nid']
            execute_db(
                "INSERT INTO stay_record (stay_id, check_in_date, check_out_date, guest_id, booking_id) "
                "VALUES (%s,%s,%s,%s,%s)",
                (new_id, request.form['check_in_date'], request.form['check_out_date'],
                 request.form['guest_id'], request.form['booking_id']))
            flash('Stay record added!', 'success')
            return redirect(url_for('stay_records_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('stay_records_form.html', row=None, guests=guests, bookings=bookings)


@app.route('/stay_records/delete/<int:id>', methods=['POST'])
def stay_records_delete(id):
    try:
        execute_db("DELETE FROM guest_feedback WHERE stay_id=%s", (id,))
        execute_db("DELETE FROM payment WHERE stay_id=%s", (id,))
        execute_db("DELETE FROM stay_record WHERE stay_id=%s", (id,))
        flash('Stay record deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('stay_records_list'))


# ──────────────────────────────────────────────
# PAYMENTS  (CRUD)
# ──────────────────────────────────────────────
@app.route('/payments')
def payments_list():
    rows = query_db("""
        SELECT p.payment_id, p.payment_date, p.amount, p.payment_method, p.payment_status,
               g.first_name || ' ' || g.last_name AS guest_name,
               sr.stay_id
        FROM payment p
        JOIN stay_record sr ON p.stay_id = sr.stay_id
        JOIN guests g ON sr.guest_id = g.guest_id
        ORDER BY p.payment_id DESC
    """)
    return render_template('payments.html', rows=rows)


@app.route('/payments/add', methods=['GET', 'POST'])
def payments_add():
    stays = query_db("""
        SELECT sr.stay_id, g.first_name || ' ' || g.last_name || ' (Stay #' || sr.stay_id || ')' AS label
        FROM stay_record sr JOIN guests g ON sr.guest_id = g.guest_id
        ORDER BY sr.stay_id DESC
    """)
    if request.method == 'POST':
        try:
            new_id = query_db("SELECT COALESCE(MAX(payment_id),0)+1 AS nid FROM payment", fetchone=True)['nid']
            execute_db(
                "INSERT INTO payment (payment_id, payment_date, amount, payment_method, payment_status, stay_id) "
                "VALUES (%s, CURRENT_DATE, %s, %s, %s, %s)",
                (new_id, request.form['amount'], request.form['payment_method'],
                 request.form['payment_status'], request.form['stay_id']))
            flash('Payment recorded!', 'success')
            return redirect(url_for('payments_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('payments_form.html', row=None, stays=stays)


@app.route('/payments/delete/<int:id>', methods=['POST'])
def payments_delete(id):
    try:
        execute_db("DELETE FROM payment WHERE payment_id=%s", (id,))
        flash('Payment deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('payments_list'))


# ──────────────────────────────────────────────
# GUEST FEEDBACK  (CRUD)
# ──────────────────────────────────────────────
@app.route('/feedback')
def feedback_list():
    rows = query_db("""
        SELECT gf.stay_id, gf.rating, gf.comments, gf.feedback_date,
               g.first_name || ' ' || g.last_name AS guest_name
        FROM guest_feedback gf
        JOIN stay_record sr ON gf.stay_id = sr.stay_id
        JOIN guests g ON sr.guest_id = g.guest_id
        ORDER BY gf.feedback_date DESC
    """)
    return render_template('feedback.html', rows=rows)


@app.route('/feedback/add', methods=['GET', 'POST'])
def feedback_add():
    stays = query_db("""
        SELECT sr.stay_id, g.first_name || ' ' || g.last_name || ' (Stay #' || sr.stay_id || ')' AS label
        FROM stay_record sr
        JOIN guests g ON sr.guest_id = g.guest_id
        WHERE sr.stay_id NOT IN (SELECT stay_id FROM guest_feedback)
        ORDER BY sr.stay_id DESC
    """)
    if request.method == 'POST':
        try:
            execute_db(
                "INSERT INTO guest_feedback (stay_id, rating, comments, feedback_date) "
                "VALUES (%s,%s,%s, CURRENT_DATE)",
                (request.form['stay_id'], request.form['rating'],
                 request.form.get('comments', '')))
            flash('Feedback added!', 'success')
            return redirect(url_for('feedback_list'))
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('feedback_form.html', row=None, stays=stays)


@app.route('/feedback/delete/<int:id>', methods=['POST'])
def feedback_delete(id):
    try:
        execute_db("DELETE FROM guest_feedback WHERE stay_id=%s", (id,))
        flash('Feedback deleted!', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('feedback_list'))


# ──────────────────────────────────────────────
# QUERIES FROM STAGE B + PROCEDURES/FUNCTIONS FROM STAGE D
# ──────────────────────────────────────────────
@app.route('/queries')
def queries_page():
    return render_template('queries.html')


@app.route('/queries/upcoming_bookings')
def query_upcoming_bookings():
    rows = query_db("""
        SELECT b.booking_id, g.first_name || ' ' || g.last_name AS guest_name,
               bs.source_name, b.check_in_date, b.check_out_date,
               b.num_guests, b.total_price, b.booking_status
        FROM bookings b
        JOIN guests g ON b.guest_id = g.guest_id
        JOIN booking_sources bs ON b.source_id = bs.source_id
        WHERE b.check_in_date >= CURRENT_DATE AND b.booking_status = 'CONFIRMED'
        ORDER BY b.check_in_date ASC
    """)
    return render_template('query_result.html', title='Upcoming Confirmed Bookings',
                           description='Shows all future confirmed bookings with guest and source details (Query 1 from Stage B)',
                           rows=rows)


@app.route('/queries/monthly_revenue')
def query_monthly_revenue():
    rows = query_db("""
        SELECT EXTRACT(YEAR FROM b.check_in_date) AS booking_year,
               EXTRACT(MONTH FROM b.check_in_date) AS booking_month,
               COUNT(*) AS number_of_bookings,
               SUM(b.total_price) AS total_revenue,
               ROUND(AVG(b.total_price),2) AS average_booking_price
        FROM bookings b
        WHERE b.booking_status IN ('CONFIRMED', 'COMPLETED')
        GROUP BY EXTRACT(YEAR FROM b.check_in_date), EXTRACT(MONTH FROM b.check_in_date)
        ORDER BY booking_year, booking_month
    """)
    return render_template('query_result.html', title='Monthly Revenue Report',
                           description='Revenue breakdown by year and month (Query 2 from Stage B)',
                           rows=rows)


@app.route('/queries/source_performance')
def query_source_performance():
    rows = query_db("""
        SELECT bs.source_name, bs.commission_rate,
               COUNT(b.booking_id) AS total_bookings,
               SUM(b.total_price) AS gross_revenue,
               ROUND(SUM(b.total_price * bs.commission_rate / 100),2) AS estimated_commission,
               ROUND(SUM(b.total_price - (b.total_price * bs.commission_rate / 100)),2) AS net_revenue
        FROM booking_sources bs
        JOIN bookings b ON bs.source_id = b.source_id
        WHERE b.booking_status IN ('CONFIRMED', 'COMPLETED')
        GROUP BY bs.source_id, bs.source_name, bs.commission_rate
        ORDER BY net_revenue DESC
    """)
    return render_template('query_result.html', title='Booking Source Performance',
                           description='Commission analysis per booking source (Query 6 from Stage B)',
                           rows=rows)


@app.route('/queries/guest_spending')
def query_guest_spending():
    rows = query_db("""
        SELECT g.first_name || ' ' || g.last_name AS guest_name,
               g.phone, g.email,
               COUNT(b.booking_id) AS total_bookings,
               COALESCE(SUM(b.total_price), 0) AS total_spent
        FROM guests g
        LEFT JOIN bookings b ON g.guest_id = b.guest_id
        GROUP BY g.guest_id, g.first_name, g.last_name, g.phone, g.email
        ORDER BY total_spent DESC
    """)
    return render_template('query_result.html', title='Guest Spending Summary',
                           description='All guests ranked by total spending (Query 4 from Stage B)',
                           rows=rows)


# ── Functions & Procedures from Stage D ──

@app.route('/queries/calculate_discount', methods=['GET', 'POST'])
def query_calculate_discount():
    guests = query_db("SELECT guest_id, first_name || ' ' || last_name AS name FROM guests ORDER BY last_name")
    result = None
    if request.method == 'POST':
        try:
            guest_id = request.form['guest_id']
            price = request.form['booking_price']
            result = query_db(
                "SELECT fn_calculate_guest_discount(%s, %s) AS discounted_price",
                (guest_id, price), fetchone=True)
            guest_name = query_db("SELECT first_name || ' ' || last_name AS n FROM guests WHERE guest_id=%s",
                                  (guest_id,), fetchone=True)['n']
            result['guest_name'] = guest_name
            result['original_price'] = float(price)
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('fn_discount.html', guests=guests, result=result)


@app.route('/queries/available_rooms', methods=['GET', 'POST'])
def query_available_rooms():
    types = query_db("SELECT type_name FROM room_types ORDER BY type_name")
    result = None
    if request.method == 'POST':
        try:
            type_name = request.form['type_name']
            min_floor = request.form.get('min_floor', 1)
            conn = get_db()
            conn.autocommit = False
            try:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                    cur.execute("SELECT fn_get_available_rooms_by_type(%s, %s, 'room_cursor')", (type_name, min_floor))
                    cur.execute("FETCH ALL FROM room_cursor")
                    result = cur.fetchall()
                conn.commit()
            finally:
                conn.close()
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('fn_available_rooms.html', types=types, result=result)


@app.route('/queries/register_loyalty', methods=['GET', 'POST'])
def query_register_loyalty():
    guests = query_db("SELECT guest_id, first_name || ' ' || last_name AS name FROM guests ORDER BY last_name")
    message = None
    if request.method == 'POST':
        try:
            guest_id = request.form['guest_id']
            conn = get_db()
            conn.autocommit = True
            try:
                with conn.cursor() as cur:
                    cur.execute("CALL pr_register_loyalty_member(%s)", (guest_id,))
                notices = conn.notices
                message = notices[-1] if notices else 'Procedure executed successfully!'
            finally:
                conn.close()
            flash(message, 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('pr_register_loyalty.html', guests=guests, message=message)


@app.route('/queries/upgrade_room_status', methods=['GET', 'POST'])
def query_upgrade_room_status():
    message = None
    if request.method == 'POST':
        try:
            min_rating = request.form['min_rating']
            conn = get_db()
            conn.autocommit = True
            try:
                with conn.cursor() as cur:
                    cur.execute("CALL pr_upgrade_room_status(%s)", (min_rating,))
                notices = conn.notices
                message = notices[-1] if notices else 'Procedure executed successfully!'
            finally:
                conn.close()
            flash(message, 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return render_template('pr_upgrade_room_status.html', message=message)


if __name__ == '__main__':
    app.run(debug=True, port=5000)

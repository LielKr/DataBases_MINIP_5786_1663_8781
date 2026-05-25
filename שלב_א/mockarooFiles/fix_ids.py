import re
import os
import random

os.chdir(r"c:\Users\lielk\source\repos\DB5786_1663_8781\DataBases_MINIP_5786_1663_8781\שלב_א\mockarooFiles")

def fix_guests():
    with open("GUESTS.sql", "r", encoding="utf-8") as f:
        content = f.read()
    
    # shift ID by 50000
    content = re.sub(r"values\s*\((\d+),", lambda m: f"values ({int(m.group(1)) + 50000},", content)
    # fix dates
    content = re.sub(r"'(\d{2})-(\d{2})-(\d{4})'", r"'\3-\2-\1'", content)
    
    with open("GUESTS_fixed.sql", "w", encoding="utf-8") as f:
        f.write(content)

def fix_bookings():
    with open("BOOKINGS.sql", "r", encoding="utf-8") as f:
        content = f.read()
    
    # shift booking_id by 50000
    content = re.sub(r"values\s*\((\d+),", lambda m: f"values ({int(m.group(1)) + 50000},", content)
    # fix dates
    content = re.sub(r"'(\d{2})-(\d{2})-(\d{4})'", r"'\3-\2-\1'", content)
    
    # replace guest_id with a random valid guest_id from 1000 to 20979
    # The line ends like: , 19576, 6);
    # We can match `, \d+, \d+\);`
    def replace_guest_id(m):
        source = m.group(1)
        valid_guest = random.randint(1000, 20979)
        return f", {valid_guest}, {source});"
        
    content = re.sub(r",\s*\d+,\s*(\d+)\);", replace_guest_id, content)
    
    with open("BOOKINGS_fixed.sql", "w", encoding="utf-8") as f:
        f.write(content)

fix_guests()
fix_bookings()
print("Fixed files created.")

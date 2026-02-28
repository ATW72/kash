import sqlite3

class DummySession(dict):
    pass

session = {'username': 'admin', 'user_id': 1}

try:
    conn = sqlite3.connect('data/expenses.db')
    cursor = conn.cursor()
    cursor.execute("PRAGMA foreign_keys = ON")
    
    cursor.execute("INSERT INTO users (username, password_hash) VALUES ('testuser', 'hash')")
    new_user_id = cursor.lastrowid
    conn.commit()
    print("Created user", new_user_id)
    
    # Try deleting it with our api simulated
    cursor.execute("DELETE FROM users WHERE id=?", (new_user_id,))
    conn.commit()
    print("Deleted successfully")
except Exception as e:
    print("Error:", repr(e))

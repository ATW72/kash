import sqlite3
import os
import sys

# Mocking session for testing if needed, or just testing the DB layer/logic
# Here we'll test the helper functions and some route logic patterns

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from utils.db import get_db_connection
from utils.auth import is_owner_or_shared, get_visible_clause

def setup_test_db():
    # We use the real DB path from config or a temp one. 
    # For now, let's just check the existing one safely.
    pass

def test_visibility():
    print("Testing visibility clause...")
    clause, params = get_visible_clause('expenses', 'user1')
    print(f"Clause: {clause}")
    print(f"Params: {params}")
    assert 'owner = ?' in clause
    assert 'user1' in params

def test_ownership_logic():
    print("Testing ownership logic...")
    conn = get_db_connection()
    
    # Create a dummy expense for testing
    c = conn.cursor()
    c.execute("INSERT INTO expenses (date, category, description, amount, paid_by, owner) VALUES (?,?,?,?,?,?)",
              ('2023-01-01', 'Test', 'Test Expense', 10.0, 'user1', 'user1'))
    eid = c.lastrowid
    
    # Test owner can see/edit
    can_see, can_edit = is_owner_or_shared(conn, 'expenses', eid, 'user1')
    print(f"Owner check: can_see={can_see}, can_edit={can_edit}")
    assert can_see is True
    assert can_edit is True
    
    # Test other user cannot see/edit
    can_see, can_edit = is_owner_or_shared(conn, 'expenses', eid, 'user2')
    print(f"Other user check: can_see={can_see}, can_edit={can_edit}")
    assert can_see is False
    assert can_edit is False
    
    # Cleanup
    conn.execute("DELETE FROM expenses WHERE id=?", (eid,))
    conn.commit()
    conn.close()

if __name__ == "__main__":
    try:
        test_visibility()
        test_ownership_logic()
        print("\nAll logical isolation tests passed!")
    except Exception as e:
        print(f"\nTests failed: {e}")
        sys.exit(1)

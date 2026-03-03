import sqlite3
import os
import sys

# Add parent directory to path to import config if needed
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config.settings import Config

def get_db_connection():
    conn = sqlite3.connect(Config.DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def fix_orphans(default_owner):
    if not default_owner:
        print("Error: Default owner required.")
        return

    tables = [
        'expenses', 'income', 'credit_cards', 'budgets', 
        'savings_goals', 'loans', 'bills', 'recurring_transactions', 'invoices'
    ]
    
    conn = get_db_connection()
    c = conn.cursor()
    
    total_fixed = 0
    
    for table in tables:
        try:
            # Count orphans
            res = c.execute(f"SELECT COUNT(*) FROM {table} WHERE owner IS NULL OR owner = ''").fetchone()
            count = res[0]
            if count > 0:
                print(f"Fixing {count} orphans in {table}...")
                c.execute(f"UPDATE {table} SET owner = ? WHERE owner IS NULL OR owner = ''", (default_owner,))
                total_fixed += count
        except sqlite3.OperationalError as e:
            print(f"Skipping table {table} (not found or missing owner column): {e}")

    conn.commit()
    conn.close()
    print(f"Successfully assigned {total_fixed} orphaned records to '{default_owner}'.")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Assign owners to orphaned database records.")
    parser.add_argument("username", help="The username to assign orphaned records to.")
    args = parser.parse_args()
    
    fix_orphans(args.username)

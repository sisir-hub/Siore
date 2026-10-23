"""Check transactional stock reservations and idempotent restocking against real schema."""
import sqlite3
from pathlib import Path
c=sqlite3.connect(':memory:'); c.executescript(Path('drizzle/0000_pretty_random.sql').read_text())
c.execute("INSERT INTO products VALUES ('p','SKU','Bracelet','',150,3,'Bracelets','','active')")
def order(id):
 c.execute("INSERT INTO orders VALUES (?,?,?,'Test','01700000000','Test address','inside','','Website',150,60,210,'Pending','2026-10-22')",(id,id,id))
order('one'); c.execute("INSERT INTO order_items VALUES ('i','one','p','Bracelet',150,2)");c.commit()
assert c.execute('SELECT stock FROM products').fetchone()[0]==1
try:
 with c:
  order('two');c.execute("INSERT INTO order_items VALUES ('j','two','p','Bracelet',150,2)")
except sqlite3.IntegrityError:pass
else:raise AssertionError('Oversell allowed')
assert c.execute("SELECT count(*) FROM orders WHERE id='two'").fetchone()[0]==0
assert c.execute('SELECT stock FROM products').fetchone()[0]==1
c.execute("UPDATE orders SET status='Cancelled' WHERE id='one'")
assert c.execute('SELECT stock FROM products').fetchone()[0]==3
c.execute("UPDATE orders SET status='Cancelled' WHERE id='one'")
assert c.execute('SELECT stock FROM products').fetchone()[0]==3
assert c.execute('SELECT count(*) FROM order_history').fetchone()[0]==1
c.commit()
try:
 with c:
  order('three');c.execute("INSERT INTO order_items VALUES ('k','three','p','Bracelet',1,1)")
except sqlite3.IntegrityError:pass
else:raise AssertionError('Changed price accepted')
print('PASS: reservation, oversell rollback, one-time restock, status history and price race protection')

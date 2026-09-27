"""Run with python test/category_sql_test.py; exercises the app's actual SQL."""
import re
import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class CategorySqlTest(unittest.TestCase):
    def test_standalone_categories_persist_and_share_product_choices(self):
        migrations = (ROOT / 'lib/core/database/db_migrations.dart').read_text()
        create = re.search(r"_createProductCategoriesTable = '''(.*?)'''", migrations, re.S).group(1)
        seed = re.search(r"_seedProductCategories = '''(.*?)'''", migrations, re.S).group(1)
        repository = (ROOT / 'lib/features/product/repositories/product_repository.dart').read_text()
        query = re.search(r"getCategories\(.*?rawQuery\(\s*'''(.*?)'''", repository, re.S).group(1)
        with sqlite3.connect(':memory:') as db:
            db.execute("CREATE TABLE products (category TEXT NOT NULL DEFAULT '')")
            db.execute("INSERT INTO products VALUES ('Kategori Lama'), ('snack')")
            db.execute(create)
            db.execute(seed)
            db.execute('INSERT INTO product_categories(name) VALUES (?)', ('Peralatan Dapur',))
            names = [row[0] for row in db.execute(query)]
            self.assertIn('Peralatan Dapur', names)
            self.assertIn('Kategori Lama', names)
            self.assertEqual(sum(n.lower() == 'snack' for n in names), 1)
            with self.assertRaises(sqlite3.IntegrityError):
                db.execute("INSERT INTO product_categories VALUES ('sNaCk')")
            with self.assertRaises(sqlite3.IntegrityError):
                db.execute("INSERT INTO product_categories VALUES ('   ')")
            with self.assertRaises(sqlite3.IntegrityError):
                db.execute('INSERT INTO product_categories VALUES (?)', ('x' * 61,))
            self.assertEqual(db.execute('SELECT count(*) FROM products').fetchone()[0], 2)

    def test_upgrade_preserves_data_and_filters_before_top_three(self):
        migrations = (ROOT / 'lib/core/database/db_migrations.dart').read_text()
        tables = re.findall(r"static const String _create\w+Table = '''(.*?)'''", migrations, re.S)
        migration = re.search(r'"(ALTER TABLE products ADD COLUMN category.*?)"', migrations).group(1)
        repository = (ROOT / 'lib/features/transaction/repositories/transaction_repository.dart').read_text()
        query = re.search(r"getTopProductsToday\(.*?rawQuery\(\s*'''(.*?)'''", repository, re.S).group(1)
        with sqlite3.connect(':memory:') as db:
            for sql in tables:
                # Reconstruct the installed v2 schema before applying the real migration.
                db.execute(re.sub(r"\s*category\s+TEXT\s+NOT NULL DEFAULT '',", '', sql))
            db.execute("INSERT INTO products(name,sell_price,cost_price,stock) VALUES('Lama',10,5,50)")
            db.execute("INSERT INTO transactions(type) VALUES('income')")
            db.execute('INSERT INTO transaction_items(transaction_id,product_id,quantity,price_at_sale) VALUES(1,1,9,10)')
            db.execute(migration)
            self.assertEqual(db.execute('SELECT name,stock,category FROM products WHERE id=1').fetchone(), ('Lama', 50, ''))
            for name, category, qty in [('TV','Elektronik',20),('Radio','Elektronik',19),('Kabel','Elektronik',18),('Keripik','Snack',4),('Biskuit','snack',3),('Permen','Snack',2),('Wafer','Snack',1),("Kue","Chef's",1)]:
                product_id = db.execute('INSERT INTO products(name,sell_price,cost_price,category) VALUES(?,10,5,?)', (name, category)).lastrowid
                db.execute('INSERT INTO transaction_items(transaction_id,product_id,quantity,price_at_sale) VALUES(1,?,?,10)', (product_id,qty))
            self.assertEqual([r[1] for r in db.execute(query, ('Snack','Snack',3))], ['Keripik','Biskuit','Permen'])
            self.assertEqual([r[1] for r in db.execute(query, (None,None,3))], ['TV','Radio','Kabel'])
            self.assertEqual([r[1] for r in db.execute(query, ('','',3))], ['Lama'])
            self.assertEqual([r[1] for r in db.execute(query, ("Chef's","Chef's",3))], ['Kue'])
            self.assertEqual(list(db.execute(query, ('Obat-obatan','Obat-obatan',3))), [])
        with sqlite3.connect(':memory:') as db:
            for sql in tables:
                db.execute(sql)
            self.assertIn('category', [r[1] for r in db.execute('PRAGMA table_info(products)')])


if __name__ == '__main__':
    unittest.main()

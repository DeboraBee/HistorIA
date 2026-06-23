import sqlite3
from contextlib import contextmanager

DB_NAME = "/app/data/alunos.db"


@contextmanager
def get_db():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def init_db():
    with get_db() as db:
        db.execute("""
        CREATE TABLE IF NOT EXISTS alunos (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            nome  TEXT    NOT NULL,
            email TEXT    NOT NULL UNIQUE,
            xp    INTEGER NOT NULL DEFAULT 0
        )
        """)
        db.commit()

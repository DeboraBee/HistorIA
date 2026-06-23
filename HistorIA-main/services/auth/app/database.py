import sqlite3
from contextlib import contextmanager

DB_NAME = "/app/data/auth.db"


@contextmanager
def get_db():
    """Context manager que garante fechamento da conexão após cada uso."""
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def init_db():
    with get_db() as db:
        db.execute("""
        CREATE TABLE IF NOT EXISTS usuarios (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            nome  TEXT    NOT NULL,
            email TEXT    NOT NULL UNIQUE,
            senha TEXT    NOT NULL,
            tipo  TEXT    NOT NULL CHECK(tipo IN ('aluno', 'professor'))
        )
        """)
        db.commit()
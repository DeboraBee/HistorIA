import sqlite3
from contextlib import contextmanager

DB_NAME = "/app/data/trilhas.db"


@contextmanager
def get_db():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
    finally:
        conn.close()


def init_db():
    with get_db() as db:
        db.execute("""
        CREATE TABLE IF NOT EXISTS trilhas (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            nome         TEXT    NOT NULL,
            professor_id INTEGER NOT NULL
        )
        """)

        db.execute("""
        CREATE TABLE IF NOT EXISTS fases (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            trilha_id INTEGER NOT NULL REFERENCES trilhas(id) ON DELETE CASCADE,
            nome      TEXT    NOT NULL,
            ordem     INTEGER NOT NULL,
            UNIQUE (trilha_id, ordem)
        )
        """)

        db.execute("""
        CREATE TABLE IF NOT EXISTS progresso (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            aluno_id   INTEGER NOT NULL,
            trilha_id  INTEGER NOT NULL REFERENCES trilhas(id) ON DELETE CASCADE,
            fase_atual INTEGER NOT NULL REFERENCES fases(id),
            UNIQUE (aluno_id, trilha_id)
        )
        """)

        db.execute("CREATE INDEX IF NOT EXISTS idx_progresso_aluno ON progresso (aluno_id)")
        db.commit()

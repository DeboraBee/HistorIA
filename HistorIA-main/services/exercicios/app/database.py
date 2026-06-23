import os
import sqlite3
from contextlib import contextmanager

DB_NAME = "/app/data/exercicios.db" if os.path.exists("/app/data") else "exercicios.db"


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
        CREATE TABLE IF NOT EXISTS respostas (
            id               INTEGER   PRIMARY KEY AUTOINCREMENT,
            aluno_id         INTEGER   NOT NULL,
            pergunta         TEXT      NOT NULL,
            resposta_usuario INTEGER   NOT NULL,
            resposta_correta INTEGER   NOT NULL,
            acertou          BOOLEAN   NOT NULL,
            data             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """)
        db.execute("CREATE INDEX IF NOT EXISTS idx_respostas_aluno ON respostas (aluno_id)")
        db.commit()

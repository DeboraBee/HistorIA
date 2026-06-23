from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from app.database import get_db, init_db
from app.schemas import TrilhaCreate, FaseCreate, ProgressoCreate, AvancarRequest
from app.rabbitmq_consumer import iniciar_consumer

app = FastAPI(root_path="/trilhas", docs_url="/docs", openapi_url="/openapi.json")
Instrumentator().instrument(app).expose(app)


@app.on_event("startup")
def startup():
    init_db()
    iniciar_consumer()


# ── Trilhas ───────────────────────────────────────────────────────────────────

@app.get("/")
def listar_trilhas():
    with get_db() as db:
        trilhas = db.execute("SELECT * FROM trilhas").fetchall()
    return {"success": True, "data": [dict(t) for t in trilhas]}


@app.post("/", status_code=201)
def criar_trilha(trilha: TrilhaCreate):
    with get_db() as db:
        cursor = db.execute(
            "INSERT INTO trilhas (nome, professor_id) VALUES (?, ?)",
            (trilha.nome, trilha.professor_id)
        )
        db.commit()
    return {"success": True, "data": {"id": cursor.lastrowid}}


@app.get("/{id}")
def buscar_trilha(id: int):
    with get_db() as db:
        trilha = db.execute(
            "SELECT * FROM trilhas WHERE id = ?", (id,)
        ).fetchone()

    if not trilha:
        raise HTTPException(status_code=404, detail="Trilha não encontrada")

    return {"success": True, "data": dict(trilha)}


@app.delete("/{id}")
def deletar_trilha(id: int):
    with get_db() as db:
        result = db.execute("DELETE FROM trilhas WHERE id = ?", (id,))
        db.commit()

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Trilha não encontrada")

    return {"success": True}


# ── Fases ─────────────────────────────────────────────────────────────────────

@app.post("/fases", status_code=201)
def criar_fase(fase: FaseCreate):
    with get_db() as db:
        trilha = db.execute(
            "SELECT id FROM trilhas WHERE id = ?", (fase.trilha_id,)
        ).fetchone()

        if not trilha:
            raise HTTPException(status_code=404, detail="Trilha não encontrada")

        try:
            cursor = db.execute(
                "INSERT INTO fases (trilha_id, nome, ordem) VALUES (?, ?, ?)",
                (fase.trilha_id, fase.nome, fase.ordem)
            )
            db.commit()
        except Exception:
            raise HTTPException(status_code=400, detail="Já existe uma fase com essa ordem nesta trilha")

    return {"success": True, "data": {"id": cursor.lastrowid}}


@app.get("/{trilha_id}/fases")
def listar_fases(trilha_id: int):
    with get_db() as db:
        fases = db.execute(
            "SELECT * FROM fases WHERE trilha_id = ? ORDER BY ordem",
            (trilha_id,)
        ).fetchall()

    return {"success": True, "data": [dict(f) for f in fases]}


# ── Progresso ─────────────────────────────────────────────────────────────────

@app.post("/progresso", status_code=201)
def iniciar_trilha(data: ProgressoCreate):
    with get_db() as db:
        existente = db.execute(
            "SELECT id FROM progresso WHERE aluno_id = ? AND trilha_id = ?",
            (data.aluno_id, data.trilha_id)
        ).fetchone()

        if existente:
            raise HTTPException(status_code=400, detail="Aluno já está nessa trilha")

        primeira_fase = db.execute(
            "SELECT id FROM fases WHERE trilha_id = ? ORDER BY ordem LIMIT 1",
            (data.trilha_id,)
        ).fetchone()

        if not primeira_fase:
            raise HTTPException(status_code=400, detail="Trilha sem fases")

        db.execute(
            "INSERT INTO progresso (aluno_id, trilha_id, fase_atual) VALUES (?, ?, ?)",
            (data.aluno_id, data.trilha_id, primeira_fase["id"])
        )
        db.commit()

    return {"success": True}


@app.get("/progresso/{aluno_id}/{trilha_id}")
def ver_progresso(aluno_id: int, trilha_id: int):
    with get_db() as db:
        progresso = db.execute(
            "SELECT * FROM progresso WHERE aluno_id = ? AND trilha_id = ?",
            (aluno_id, trilha_id)
        ).fetchone()

    if not progresso:
        raise HTTPException(status_code=404, detail="Progresso não encontrado")

    return {"success": True, "data": dict(progresso)}


@app.post("/progresso/avancar")
def avancar_fase(data: AvancarRequest):
    with get_db() as db:
        progresso = db.execute(
            "SELECT * FROM progresso WHERE aluno_id = ? AND trilha_id = ?",
            (data.aluno_id, data.trilha_id)
        ).fetchone()

        if not progresso:
            raise HTTPException(status_code=404, detail="Progresso não encontrado")

        proxima = db.execute(
            """
            SELECT * FROM fases
            WHERE trilha_id = ? AND ordem > (
                SELECT ordem FROM fases WHERE id = ?
            )
            ORDER BY ordem
            LIMIT 1
            """,
            (data.trilha_id, progresso["fase_atual"])
        ).fetchone()

        if not proxima:
            return {"success": True, "data": {"concluida": True, "nova_fase": None}}

        db.execute(
            "UPDATE progresso SET fase_atual = ? WHERE aluno_id = ? AND trilha_id = ?",
            (proxima["id"], data.aluno_id, data.trilha_id)
        )
        db.commit()

    return {"success": True, "data": {"concluida": False, "nova_fase": proxima["id"]}}

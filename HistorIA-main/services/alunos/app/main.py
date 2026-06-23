from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator

from app.database import get_db, init_db
from app.schemas import AlunoCreate, AlunoUpdate
from app.rabbitmq_consumer import iniciar_consumer


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    iniciar_consumer()
    yield


app = FastAPI(root_path="/alunos", lifespan=lifespan)
Instrumentator().instrument(app).expose(app)


@app.get("/")
def listar():
    with get_db() as db:
        alunos = db.execute("SELECT * FROM alunos").fetchall()
    return {"success": True, "data": [dict(a) for a in alunos]}


@app.post("/", status_code=201)
def criar(aluno: AlunoCreate):
    with get_db() as db:
        try:
            cursor = db.execute(
                "INSERT INTO alunos (nome, email) VALUES (?, ?)",
                (aluno.nome, aluno.email),
            )
            db.commit()
            return {"success": True, "data": {"id": cursor.lastrowid}}
        except Exception:
            raise HTTPException(status_code=400, detail="Email já cadastrado")


@app.get("/{id}")
def buscar(id: int):
    with get_db() as db:
        aluno = db.execute(
            "SELECT * FROM alunos WHERE id = ?", (id,)
        ).fetchone()

    if not aluno:
        raise HTTPException(status_code=404, detail="Aluno não encontrado")

    return {"success": True, "data": dict(aluno)}


@app.put("/{id}")
def atualizar(id: int, dados: AlunoUpdate):
    updates, params = [], []

    if dados.nome  is not None: updates.append("nome = ?");  params.append(dados.nome)
    if dados.email is not None: updates.append("email = ?"); params.append(dados.email)
    if dados.xp    is not None: updates.append("xp = ?");    params.append(dados.xp)

    if not updates:
        raise HTTPException(status_code=400, detail="Nenhum campo enviado")

    params.append(id)

    with get_db() as db:
        db.execute(f"UPDATE alunos SET {', '.join(updates)} WHERE id = ?", params)
        db.commit()

    return {"success": True}


@app.delete("/{id}")
def deletar(id: int):
    with get_db() as db:
        result = db.execute("DELETE FROM alunos WHERE id = ?", (id,))
        db.commit()

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Aluno não encontrado")

    return {"success": True}

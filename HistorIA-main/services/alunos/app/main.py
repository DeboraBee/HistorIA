from fastapi import FastAPI, HTTPException
from app.database import get_db, init_db
from app.schemas import AlunoCreate, AlunoUpdate, RespostaRequest
from app.rabbitmq_consumer import iniciar_consumer

app = FastAPI(
    root_path="/alunos",
    docs_url="/docs",
    openapi_url="/openapi.json"
)


@app.on_event("startup")
def startup():
    init_db()
    iniciar_consumer()


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
                (aluno.nome, aluno.email)
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


@app.post("/responder")
def responder(resposta: RespostaRequest):
    with get_db() as db:
        aluno = db.execute(
            "SELECT * FROM alunos WHERE id = ?", (resposta.aluno_id,)
        ).fetchone()

        if not aluno:
            raise HTTPException(status_code=404, detail="Aluno não encontrado")

        xp_ganho = 10 if resposta.correta else 0
        novo_xp = aluno["xp"] + xp_ganho

        db.execute(
            "UPDATE alunos SET xp = ? WHERE id = ?",
            (novo_xp, resposta.aluno_id)
        )
        db.commit()

    return {"success": True, "data": {"xp_ganho": xp_ganho, "xp_total": novo_xp}}

from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator

from app.database import get_db, init_db
from app.schemas import GerarRequest, ResolverRequest, JogarRequest
from app.ai_client import gerar_questoes
from app.rabbitmq_publisher import publicar_resposta


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(root_path="/exercicios", lifespan=lifespan)
Instrumentator().instrument(app).expose(app)


@app.post("/gerar")
def gerar(request: GerarRequest):
    questoes = gerar_questoes(request.tema, request.quantidade)

    if not questoes:
        raise HTTPException(status_code=500, detail="Erro ao gerar questões")

    return {"success": True, "data": questoes}


@app.post("/resolver")
def resolver(req: ResolverRequest):
    if req.resposta_usuario >= len(req.opcoes):
        raise HTTPException(status_code=400, detail="Resposta inválida")

    correta = req.resposta_usuario == req.resposta_correta
    return {"success": True, "data": {"correta": correta}}


@app.post("/jogar")
def jogar(req: JogarRequest):
    if req.resposta_usuario >= len(req.opcoes):
        raise HTTPException(status_code=400, detail="Resposta inválida")

    correta = req.resposta_usuario == req.resposta_correta

    with get_db() as db:
        db.execute(
            """
            INSERT INTO respostas
                (aluno_id, pergunta, resposta_usuario, resposta_correta, acertou)
            VALUES (?, ?, ?, ?, ?)
            """,
            (req.aluno_id, req.pergunta, req.resposta_usuario, req.resposta_correta, correta),
        )
        db.commit()

    publicar_resposta(req.aluno_id, req.trilha_id, correta)

    return {"success": True, "data": {"correta": correta}}


@app.get("/historico/{aluno_id}")
def historico(aluno_id: int):
    with get_db() as db:
        respostas = db.execute(
            "SELECT * FROM respostas WHERE aluno_id = ? ORDER BY data DESC",
            (aluno_id,),
        ).fetchall()

    return {"success": True, "data": [dict(r) for r in respostas]}

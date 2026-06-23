from fastapi import FastAPI, HTTPException
from app.database import get_db, init_db
from app.schemas import GerarRequest, JogarRequest
from app.ai_client import gerar_questoes
from app.alunos_client import enviar_resultado
from app.trilhas_client import avancar_fase

app = FastAPI(root_path="/exercicios")


@app.on_event("startup")
def startup():
    init_db()


@app.post("/gerar")
def gerar(request: GerarRequest):
    questoes = gerar_questoes(request.tema, request.quantidade)

    if not questoes:
        raise HTTPException(status_code=500, detail="Erro ao gerar questões")

    return {"success": True, "data": questoes}


@app.post("/jogar")
def jogar(req: JogarRequest):
    if req.resposta_usuario >= len(req.opcoes):
        raise HTTPException(status_code=400, detail="Resposta inválida")

    correta = req.resposta_usuario == req.resposta_correta

    # 1. Salva histórico
    with get_db() as db:
        db.execute(
            """
            INSERT INTO respostas
                (aluno_id, pergunta, resposta_usuario, resposta_correta, acertou)
            VALUES (?, ?, ?, ?, ?)
            """,
            (req.aluno_id, req.pergunta, req.resposta_usuario, req.resposta_correta, correta)
        )
        db.commit()

    # 2. Atualiza XP no serviço de alunos
    resultado_xp = enviar_resultado(req.aluno_id, correta)

    # 3. Avança fase SE acertou
    progresso = avancar_fase(req.aluno_id, req.trilha_id) if correta else None

    return {
        "success": True,
        "data": {
            "correta": correta,
            "xp": resultado_xp["data"] if resultado_xp else None,
            "progresso": progresso
        }
    }


@app.get("/historico/{aluno_id}")
def historico(aluno_id: int):
    with get_db() as db:
        respostas = db.execute(
            "SELECT * FROM respostas WHERE aluno_id = ? ORDER BY data DESC",
            (aluno_id,)
        ).fetchall()

    return {"success": True, "data": [dict(r) for r in respostas]}

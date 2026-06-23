from pydantic import BaseModel
from typing import List


class GerarRequest(BaseModel):
    tema: str
    quantidade: int


class Questao(BaseModel):
    pergunta: str
    opcoes: List[str]
    resposta_correta: int


class JogarRequest(BaseModel):
    aluno_id: int
    trilha_id: int
    pergunta: str
    opcoes: List[str]
    resposta_usuario: int
    resposta_correta: int

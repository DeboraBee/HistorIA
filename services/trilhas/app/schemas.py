from pydantic import BaseModel
 
 
class TrilhaCreate(BaseModel):
    nome: str
    professor_id: int
 
 
class FaseCreate(BaseModel):
    trilha_id: int
    nome: str
    ordem: int
 
 
class ProgressoCreate(BaseModel):
    aluno_id: int
    trilha_id: int
 
 
class AvancarRequest(BaseModel):
    aluno_id: int
    trilha_id: int
from pydantic import BaseModel, EmailStr
from typing import Optional

class AlunoCreate(BaseModel):
    nome: str
    email: EmailStr

class AlunoUpdate(BaseModel):
    nome: Optional[str] = None
    email: Optional[EmailStr] = None
    xp: Optional[int] = None

class RespostaRequest(BaseModel):
    aluno_id: int
    correta: bool
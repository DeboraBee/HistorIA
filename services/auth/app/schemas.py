from pydantic import BaseModel, EmailStr


class UsuarioCreate(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    tipo: str  # "aluno" ou "professor"


class LoginRequest(BaseModel):
    email: EmailStr
    senha: str


class UsuarioResponse(BaseModel):
    id: int
    nome: str
    tipo: str


class LoginResponse(BaseModel):
    success: bool
    token: str
    data: UsuarioResponse
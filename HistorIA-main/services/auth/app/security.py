import os
from datetime import datetime, timedelta
from passlib.context import CryptContext
from jose import JWTError, jwt

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Em produção, defina JWT_SECRET no .env com um valor longo e aleatório
SECRET_KEY = os.getenv("JWT_SECRET", "troque-esta-chave-em-producao")
ALGORITHM = "HS256"
TOKEN_EXPIRE_HOURS = 8


def hash_senha(senha: str) -> str:
    return pwd_context.hash(senha)


def verificar_senha(senha: str, hash: str) -> bool:
    return pwd_context.verify(senha, hash)


def criar_token(dados: dict) -> str:
    payload = dados.copy()
    payload["exp"] = datetime.utcnow() + timedelta(hours=TOKEN_EXPIRE_HOURS)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decodificar_token(token: str) -> dict:
    """Retorna o payload do token ou lança JWTError se inválido/expirado."""
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
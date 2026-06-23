from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from prometheus_fastapi_instrumentator import Instrumentator

from app.database import get_db, init_db
from app.schemas import UsuarioCreate, LoginRequest, LoginResponse, UsuarioResponse
from app.security import hash_senha, verificar_senha, criar_token, decodificar_token


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(root_path="/auth", lifespan=lifespan)
Instrumentator().instrument(app).expose(app)
bearer = HTTPBearer()


def usuario_autenticado(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
) -> dict:
    try:
        return decodificar_token(credentials.credentials)
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido ou expirado")


@app.post("/registrar", status_code=201)
def registrar(usuario: UsuarioCreate):
    with get_db() as db:
        try:
            db.execute(
                "INSERT INTO usuarios (nome, email, senha, tipo) VALUES (?, ?, ?, ?)",
                (usuario.nome, usuario.email, hash_senha(usuario.senha), usuario.tipo),
            )
            db.commit()
        except Exception:
            raise HTTPException(status_code=400, detail="Email já cadastrado")

    return {"success": True}


@app.post("/login", response_model=LoginResponse)
def login(dados: LoginRequest):
    with get_db() as db:
        user = db.execute(
            "SELECT * FROM usuarios WHERE email = ?", (dados.email,)
        ).fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    if not verificar_senha(dados.senha, user["senha"]):
        raise HTTPException(status_code=401, detail="Senha inválida")

    token = criar_token({"sub": str(user["id"]), "tipo": user["tipo"]})

    return LoginResponse(
        success=True,
        token=token,
        data=UsuarioResponse(
            id=user["id"],
            nome=user["nome"],
            email=user["email"],
            tipo=user["tipo"],
        ),
    )


@app.get("/me")
def me(payload: dict = Depends(usuario_autenticado)):
    with get_db() as db:
        user = db.execute(
            "SELECT id, nome, email, tipo FROM usuarios WHERE id = ?",
            (payload["sub"],),
        ).fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    return {"success": True, "data": dict(user)}

import pytest
import sqlite3
import os
import tempfile
from unittest.mock import patch
from fastapi.testclient import TestClient
from app.main import app
from app.database import DB_NAME, init_db

@pytest.fixture(autouse=True)
def setup_teardown():
    """Limpa o banco antes e depois de cada teste"""
    # Remove banco existente se houver
    try:
        if os.path.exists(DB_NAME):
            os.remove(DB_NAME)
    except:
        pass
    
    # Inicializa novo banco
    init_db()
    
    yield
    
    # Limpeza após teste
    try:
        if os.path.exists(DB_NAME):
            os.remove(DB_NAME)
    except:
        pass

@pytest.fixture
def client():
    """Fixture do TestClient"""
    return TestClient(app)

class TestAlunosAPI:
    """Testes para o serviço de Alunos"""
    
    def test_criar_aluno_valido(self, client):
        """Testa criação de um aluno com dados válidos"""
        response = client.post("/", json={
            "nome": "João Silva",
            "email": "joao@example.com"
        })
        assert response.status_code == 201
        data = response.json()
        assert data["success"] is True
        assert "id" in data["data"]
    
    def test_criar_aluno_email_invalido(self, client):
        """Testa criação com email inválido"""
        response = client.post("/", json={
            "nome": "Maria",
            "email": "email_invalido"
        })
        assert response.status_code == 422  # Validation error
    
    def test_criar_aluno_sem_nome(self, client):
        """Testa criação sem nome (campo obrigatório)"""
        response = client.post("/", json={
            "email": "teste@example.com"
        })
        assert response.status_code == 422
    
    def test_buscar_aluno_existente(self, client):
        """Testa busca de um aluno existente"""
        # Cria um aluno
        create_response = client.post("/", json={
            "nome": "Pedro",
            "email": "pedro@example.com"
        })
        aluno_id = create_response.json()["data"]["id"]
        
        # Busca o aluno
        response = client.get(f"/{aluno_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["nome"] == "Pedro"
        assert data["data"]["email"] == "pedro@example.com"
        assert data["data"]["xp"] == 0
    
    def test_buscar_aluno_inexistente(self, client):
        """Testa busca de um aluno que não existe"""
        response = client.get("/999")
        assert response.status_code == 404
        assert "não encontrado" in response.json()["detail"].lower()
    
    def test_multiplos_alunos(self, client):
        """Testa criação e busca de múltiplos alunos"""
        alunos = [
            {"nome": "Ana", "email": "ana@example.com"},
            {"nome": "Bruno", "email": "bruno@example.com"},
            {"nome": "Carla", "email": "carla@example.com"}
        ]
        
        ids = []
        for aluno in alunos:
            response = client.post("/", json=aluno)
            assert response.status_code == 201
            ids.append(response.json()["data"]["id"])
        
        # Verifica que todos foram criados com IDs diferentes
        assert len(set(ids)) == 3
        
        # Busca cada um
        for i, aluno_id in enumerate(ids):
            response = client.get(f"/{aluno_id}")
            assert response.status_code == 200
            assert response.json()["data"]["nome"] == alunos[i]["nome"]
    
    def test_email_duplicado(self, client):
        """Testa se permite ou nega emails duplicados"""
        email = "duplicado@example.com"
        
        # Primeira criação
        response1 = client.post("/", json={
            "nome": "Primeiro",
            "email": email
        })
        assert response1.status_code == 200
        
        # Segunda criação com mesmo email deve ser rejeitada
        response2 = client.post("/", json={
            "nome": "Segundo",
            "email": email
        })
        assert response2.status_code == 400

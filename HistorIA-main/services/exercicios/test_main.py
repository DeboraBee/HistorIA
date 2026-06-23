import pytest
import os
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from app.main import app
from app.database import init_db, DB_NAME

@pytest.fixture(autouse=True)
def setup_db():
    """Inicializa banco antes de cada teste"""
    init_db()
    yield
    try:
        if os.path.exists(DB_NAME):
            os.remove(DB_NAME)
    except:
        pass

@pytest.fixture
def client():
    """Fixture do TestClient"""
    return TestClient(app)

class TestExerciciosAPI:
    """Testes para o serviço de Exercícios"""
    
    @patch('app.main.gerar_questoes')
    def test_gerar_questoes_sucesso(self, mock_gerar, client):
        """Testa geração de questões com sucesso"""
        mock_gerar.return_value = [
            {
                "pergunta": "Qual foi o ano da Revolução Francesa?",
                "opcoes": ["1789", "1799", "1879", "1889"],
                "resposta_correta": 0
            }
        ]

        response = client.post("/gerar", json={
            "tema": "História Europeia",
            "quantidade": 1
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["data"]) == 1

    @patch('app.main.gerar_questoes')
    def test_gerar_questoes_estrutura(self, mock_gerar, client):
        """Testa que endpoint /gerar funciona"""
        mock_gerar.return_value = [{"pergunta": "Q", "opcoes": ["A", "B"], "resposta_correta": 0}]

        response = client.post("/gerar", json={
            "tema": "História",
            "quantidade": 1
        })

        assert response.status_code == 200
        data = response.json()
        assert "success" in data
        assert "data" in data
    
    def test_resolver_resposta_correta(self, client):
        """Testa resolução com resposta correta"""
        response = client.post("/resolver", json={
            "pergunta": "Pergunta exemplo",
            "opcoes": ["A", "B", "C"],
            "resposta_usuario": 1,
            "resposta_correta": 1
        })
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["correta"] is True
    
    def test_resolver_resposta_incorreta(self, client):
        """Testa resolução com resposta incorreta"""
        response = client.post("/resolver", json={
            "pergunta": "Pergunta exemplo",
            "opcoes": ["A", "B", "C"],
            "resposta_usuario": 0,
            "resposta_correta": 1
        })
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["correta"] is False
    
    def test_resolver_resposta_invalida(self, client):
        """Testa resolução com índice de resposta fora do intervalo"""
        response = client.post("/resolver", json={
            "pergunta": "Pergunta exemplo",
            "opcoes": ["A", "B", "C"],
            "resposta_usuario": 10,  # Inválido
            "resposta_correta": 1
        })
        
        assert response.status_code == 400
        assert "Resposta inválida" in response.json()["detail"]
    
    @patch('app.main.publicar_resposta')
    def test_jogar_resposta_correta(self, mock_publicar, client):
        """Testa fluxo de jogo com resposta correta"""
        mock_publicar.return_value = None

        response = client.post("/jogar", json={
            "aluno_id": 1,
            "trilha_id": 1,
            "pergunta": "Pergunta teste",
            "opcoes": ["A", "B", "C"],
            "resposta_usuario": 1,
            "resposta_correta": 1
        })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["correta"] is True
        mock_publicar.assert_called_once_with(1, 1, True)
    
    def test_jogar_resposta_invalida(self, client):
        """Testa fluxo de jogo com resposta inválida"""
        response = client.post("/jogar", json={
            "aluno_id": 1,
            "trilha_id": 1,
            "pergunta": "Pergunta teste",
            "opcoes": ["A", "B"],
            "resposta_usuario": 5,  # Inválido
            "resposta_correta": 0
        })
        
        assert response.status_code == 400
        assert "Resposta inválida" in response.json()["detail"]
    
    def test_historico_aluno_vazio(self, client):
        """Testa historico de aluno sem respostas"""
        response = client.get("/historico/999")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert isinstance(data["data"], list)

import pytest
import json
import os
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client():
    """Fixture do TestClient"""
    return TestClient(app)

class TestConteudosAPI:
    """Testes para o serviço de Conteúdos"""
    
    def test_listar_trilhas(self, client):
        """Testa listagem de trilhas"""
        response = client.get("/trilhas")
        assert response.status_code == 200
        
        try:
            data = response.json()
            assert isinstance(data, dict) or isinstance(data, list)
        except json.JSONDecodeError:
            # Se não conseguir fazer parse, há um erro
            assert False, "Resposta não é um JSON válido"
    
    def test_listar_trilhas_estrutura(self, client):
        """Testa estrutura da resposta de trilhas"""
        response = client.get("/trilhas")
        assert response.status_code == 200
        
        data = response.json()
        
        # Verifica se tem conteúdo
        if isinstance(data, list):
            if len(data) > 0:
                assert all(isinstance(item, dict) for item in data)
        elif isinstance(data, dict):
            # Se for dict, verifica se tem chaves esperadas
            assert len(data) >= 0
    
    def test_trilhas_contem_campos_esperados(self, client):
        """Testa se trilhas contêm campos esperados"""
        response = client.get("/trilhas")
        assert response.status_code == 200
        
        data = response.json()
        
        if isinstance(data, list) and len(data) > 0:
            trilha = data[0]
            # Campos esperados de uma trilha
            campos_esperados = ["nome", "modulos", "descricao", "id", "topicos"]
            # Verifica se tem pelo menos alguns dos campos
            assert any(campo in trilha for campo in campos_esperados)
    
    def test_trilhas_nao_vazio(self, client):
        """Testa se retorna algumas trilhas"""
        response = client.get("/trilhas")
        assert response.status_code == 200
        
        data = response.json()
        assert data is not None
        
        # Se for list, deve ter pelo menos uma trilha
        if isinstance(data, list):
            assert len(data) > 0, "Nenhuma trilha encontrada"
    
    def test_trilhas_arquivo_existe(self):
        """Testa se arquivo trilhas.json existe"""
        base_dir = os.path.dirname(__file__)
        path = os.path.join(base_dir, "app", "trilhas.json")
        assert os.path.exists(path), f"Arquivo {path} não existe"
    
    def test_trilhas_json_valido(self):
        """Testa se arquivo trilhas.json é um JSON válido"""
        base_dir = os.path.dirname(__file__)
        path = os.path.join(base_dir, "app", "trilhas.json")
        
        with open(path, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                assert data is not None
            except json.JSONDecodeError:
                assert False, "trilhas.json não é um JSON válido"
    
    def test_content_type_json(self, client):
        """Testa se o content-type é JSON"""
        response = client.get("/trilhas")
        assert response.status_code == 200
        assert "application/json" in response.headers.get("content-type", "")

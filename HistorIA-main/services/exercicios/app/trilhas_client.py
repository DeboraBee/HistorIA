import requests
import logging

TRILHAS_URL = "http://trilhas:8000"  # porta interna do container, não a do host


def avancar_fase(aluno_id: int, trilha_id: int):
    try:
        response = requests.post(
            f"{TRILHAS_URL}/progresso/avancar",
            json={                          # body JSON, não query params
                "aluno_id": aluno_id,
                "trilha_id": trilha_id
            },
            timeout=5
        )
        response.raise_for_status()
        return response.json()

    except Exception as e:
        logging.error(f"Erro ao avançar fase: {e}")
        return None

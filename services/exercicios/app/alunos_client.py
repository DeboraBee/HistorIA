import requests
import logging

ALUNOS_URL = "http://alunos:8000"  # 👈 MUITO IMPORTANTE

def enviar_resultado(aluno_id: int, correta: bool):
    try:
        response = requests.post(
            f"{ALUNOS_URL}/responder",
            json={
                "aluno_id": aluno_id,
                "correta": correta
            },
            timeout=5
        )

        response.raise_for_status()

        return response.json()

    except Exception as e:
        logging.error(f"Erro ao comunicar com alunos: {e}")
        return None
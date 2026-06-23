import os
import json
import requests
import logging
from dotenv import load_dotenv

load_dotenv()

def gerar_questoes(tema: str, quantidade: int):
    api_key = os.getenv("MISTRAL_API_KEY")
    url = "https://api.mistral.ai/v1/chat/completions"

    prompt = f"""
    Gere {quantidade} questões de múltipla escolha sobre {tema}.

    IMPORTANTE:
    - Não repita perguntas
    - Cada questão deve abordar um aspecto diferente do tema
    - Varie o nível de dificuldade
    - Evite perguntas genéricas
    - Retorne EXATAMENTE {quantidade} questões

    Responda APENAS em JSON no formato:
    [
      {{
        "pergunta": "...",
        "opcoes": ["A", "B", "C", "D"],
        "resposta_correta": 0
      }}
    ]
    """

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }

    data = {
        "model": "open-mistral-nemo",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.9
    }

    try:
        response = requests.post(
            url,
            headers=headers,
            json=data,
            timeout=10
        )

        response.raise_for_status()

        content = response.json()['choices'][0]['message']['content']

        # 🔥 Limpeza de markdown (```json ... ```)
        content = content.strip()
        if content.startswith("```"):
            content = content.split("```")[1].strip()

        questoes = json.loads(content)

        if not isinstance(questoes, list):
            raise ValueError("Resposta da IA não é uma lista")

        questoes = questoes[:quantidade]

        return questoes

    except Exception as e:
        logging.error(f"Erro IA: {e}")
        return []
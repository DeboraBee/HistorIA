import json
import logging
import os

import pika

RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://admin:admin@rabbitmq:5672/")
EXCHANGE = "exercicio.eventos"


def publicar_resposta(aluno_id: int, trilha_id: int, acertou: bool) -> None:
    xp_ganho = 10 if acertou else 0
    mensagem = json.dumps({
        "aluno_id": aluno_id,
        "trilha_id": trilha_id,
        "acertou": acertou,
        "xp_ganho": xp_ganho,
    })
    try:
        conn = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
        ch = conn.channel()
        ch.exchange_declare(exchange=EXCHANGE, exchange_type="fanout", durable=True)
        ch.basic_publish(
            exchange=EXCHANGE,
            routing_key="",
            body=mensagem,
            properties=pika.BasicProperties(delivery_mode=2),  # mensagem persistente
        )
        conn.close()
    except Exception as exc:
        logging.error("Erro ao publicar no RabbitMQ: %s", exc)

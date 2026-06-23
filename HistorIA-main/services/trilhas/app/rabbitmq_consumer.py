import json
import logging
import os
import threading
import time

import pika

from app.database import get_db

RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://admin:admin@rabbitmq:5672/")
EXCHANGE = "exercicio.eventos"
QUEUE = "trilhas.fase_avanco"


def _processar(ch, method, _properties, body) -> None:
    try:
        msg = json.loads(body)

        # Avança fase somente se o aluno acertou
        if not msg.get("acertou", False):
            ch.basic_ack(delivery_tag=method.delivery_tag)
            return

        aluno_id: int = msg["aluno_id"]
        trilha_id: int = msg["trilha_id"]

        with get_db() as db:
            progresso = db.execute(
                "SELECT fase_atual FROM progresso WHERE aluno_id = ? AND trilha_id = ?",
                (aluno_id, trilha_id),
            ).fetchone()

            if not progresso:
                ch.basic_ack(delivery_tag=method.delivery_tag)
                return

            proxima = db.execute(
                """
                SELECT id FROM fases
                WHERE trilha_id = ? AND ordem > (
                    SELECT ordem FROM fases WHERE id = ?
                )
                ORDER BY ordem
                LIMIT 1
                """,
                (trilha_id, progresso["fase_atual"]),
            ).fetchone()

            if proxima:
                db.execute(
                    "UPDATE progresso SET fase_atual = ? WHERE aluno_id = ? AND trilha_id = ?",
                    (proxima["id"], aluno_id, trilha_id),
                )
                db.commit()

        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as exc:
        logging.error("Erro ao processar mensagem de fase: %s", exc)
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)


def _loop() -> None:
    while True:
        try:
            conn = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
            ch = conn.channel()
            ch.exchange_declare(exchange=EXCHANGE, exchange_type="fanout", durable=True)
            ch.queue_declare(queue=QUEUE, durable=True)
            ch.queue_bind(queue=QUEUE, exchange=EXCHANGE)
            ch.basic_qos(prefetch_count=1)
            ch.basic_consume(queue=QUEUE, on_message_callback=_processar)
            logging.info("Consumer trilhas.fase_avanco iniciado.")
            ch.start_consuming()
        except Exception as exc:
            logging.warning("RabbitMQ indisponível, reconectando em 5s: %s", exc)
            time.sleep(5)


def iniciar_consumer() -> None:
    threading.Thread(target=_loop, daemon=True, name="consumer-trilhas").start()

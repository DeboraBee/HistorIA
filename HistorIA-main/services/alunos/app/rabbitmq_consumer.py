import json
import logging
import os
import threading
import time

import pika

from app.database import get_db

RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://admin:admin@rabbitmq:5672/")
EXCHANGE = "exercicio.eventos"
QUEUE = "alunos.xp_update"


def _processar(ch, method, _properties, body) -> None:
    try:
        msg = json.loads(body)
        xp_ganho: int = msg.get("xp_ganho", 0)

        with get_db() as db:
            aluno = db.execute(
                "SELECT xp FROM alunos WHERE id = ?", (msg["aluno_id"],)
            ).fetchone()

            if aluno:
                db.execute(
                    "UPDATE alunos SET xp = ? WHERE id = ?",
                    (aluno["xp"] + xp_ganho, msg["aluno_id"]),
                )
                db.commit()

        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as exc:
        logging.error("Erro ao processar mensagem de XP: %s", exc)
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
            logging.info("Consumer alunos.xp_update iniciado.")
            ch.start_consuming()
        except Exception as exc:
            logging.warning("RabbitMQ indisponível, reconectando em 5s: %s", exc)
            time.sleep(5)


def iniciar_consumer() -> None:
    threading.Thread(target=_loop, daemon=True, name="consumer-alunos").start()

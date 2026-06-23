from sqlalchemy import Column, Integer, String, Boolean, DateTime
from datetime import datetime

class Resposta(Base):
    __tablename__ = "respostas"

    id = Column(Integer, primary_key=True, index=True)
    aluno_id = Column(Integer)
    pergunta = Column(String)
    resposta_usuario = Column(Integer)
    resposta_correta = Column(Integer)
    acertou = Column(Boolean)
    data = Column(DateTime, default=datetime.utcnow)
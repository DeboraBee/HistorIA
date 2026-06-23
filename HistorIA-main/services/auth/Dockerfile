FROM python:3.11-slim

WORKDIR /app

# Dependências primeiro — preserva cache do Docker se o código mudar
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Diretório para o banco SQLite persistido via volume
RUN mkdir -p /app/data

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

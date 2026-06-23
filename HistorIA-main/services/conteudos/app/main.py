from fastapi import FastAPI
import json
import os

app = FastAPI(root_path="/conteudos")

@app.get("/trilhas")
def listar_trilhas():
    base_dir = os.path.dirname(__file__)
    path = os.path.join(base_dir, "trilhas.json")

    with open(path, encoding="utf-8") as f:
        return json.load(f)
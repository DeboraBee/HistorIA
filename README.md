testeteste
# HistorIA

Plataforma educacional gamificada para ensino de História, inspirada no Duolingo.

---

## 🚀 Como rodar

```bash
cp .env.example .env
# adicione sua chave MISTRAL_API_KEY

docker compose up --build

🌐 Acessos

- Frontend: http://localhost
- Gateway: http://localhost

Swagger:
- Exercícios: http://localhost:8001/docs
- Alunos: http://localhost:8002/docs
- Conteúdo: http://localhost:8003/docs

🧠 Arquitetura

Arquitetura de microsserviços simplificada:
Frontend → API Gateway (Nginx) → Serviços

| Serviço    | Porta | Função                     |
| ---------- | ----- | -------------------------- |
| exercícios | 8001  | Geração de questões com IA |
| alunos     | 8002  | CRUD de alunos             |
| conteúdo   | 8003  | Trilhas estáticas          |

Estrutura de pastas
historia-app/
├── .env                        # API keys (não sobe pro Git)
├── .gitignore
├── README.md
├── docker-compose.yml          # orquestra todos os containers
├── data/                       # volume Docker — persiste os .db entre restarts
├── api-gateway/
│   ├── Dockerfile
│   └── nginx.conf
├── servico-exercicios/
│   ├── main.py                 # FastAPI + chamada ao LLM
│   ├── requirements.txt        # fastapi, uvicorn, openai
│   └── Dockerfile
├── servico-alunos/
│   ├── main.py                 # FastAPI + - SQLite
│   ├── requirements.txt        # fastapi, u- vicorn
│   └── Dockerfi- le
├── servico-conteudo/
│   ├── main.py                 # FastAPI + leitura de JSON
│   ├── trilhas.json            # dados estáticos das aulas
│   ├── requirements.txt        # fastapi, uvicorn
│   └── Dockerfile
└── frontend/
    └── index.html              # HTML puro — chama os 3 serviços via fetch()

🧰 Stack
- FastAPI
- SQLite
- Docker Compose
- Nginx
- Mistral AI

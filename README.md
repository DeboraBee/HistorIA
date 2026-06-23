# HistorIA

Plataforma educacional gamificada para o ensino de História, baseada em microsserviços e com geração de questões por IA.

---

## Arquitetura

```
                         ┌─────────────────────────────────────┐
  Flutter App ──────────►│           Nginx Gateway             │
                         │         (porta 80 → /auth,          │
                         │   /exercicios, /alunos, /trilhas,   │
                         │           /conteudos)                │
                         └────────────────┬────────────────────┘
                                          │
               ┌──────────────────────────┼──────────────────────────┐
               │                          │                          │
        ┌──────▼──────┐          ┌────────▼──────┐          ┌───────▼──────┐
        │    auth     │          │   exercicios  │          │   trilhas    │
        │  (FastAPI)  │          │  (FastAPI)    │          │  (FastAPI)   │
        │  SQLite     │          │  SQLite + IA  │          │  SQLite      │
        └─────────────┘          └───────┬───────┘          └──────┬───────┘
                                         │ publica                 │ consome
                                  ┌──────▼──────────────────────────▼───────┐
                                  │              RabbitMQ                    │
                                  │   fanout exchange: exercicio.eventos     │
                                  └──────────────────┬───────────────────────┘
                                                     │ consome
                                              ┌──────▼──────┐
                                              │    alunos   │
                                              │  (FastAPI)  │
                                              │  SQLite     │
                                              └─────────────┘

        ┌─────────────┐
        │  conteudos  │   (serviço independente, sem banco)
        │  (FastAPI)  │
        └─────────────┘
```

### Serviços

| Serviço | Porta interna | Responsabilidade |
|---|---|---|
| `auth` | 8000 | Cadastro, login, JWT |
| `exercicios` | 8001 | Gerar questões via IA (OpenAI), registrar respostas |
| `alunos` | 8002 | Perfil e XP dos alunos |
| `trilhas` | 8003 | Trilhas e fases de aprendizado |
| `conteudos` | 8004 | Conteúdos educacionais |
| `gateway` (Nginx) | 80 | Roteamento e CORS |
| `rabbitmq` | 5672 / 15672 | Fila de mensagens assíncronas |

---

## Como rodar

### Pré-requisitos

- Docker e Docker Compose
- Flutter SDK (para o app mobile)

### Backend (Docker Compose)

```bash
# Clone o repositório
git clone https://github.com/Deborange/HistorIA.git
cd HistorIA

# Crie o arquivo de variáveis de ambiente
echo "JWT_SECRET=sua-chave-secreta-aqui" > .env

# Suba todos os serviços
docker compose up --build
```

O gateway estará disponível em `http://localhost:80`.

**Variáveis de ambiente obrigatórias** (arquivo `.env` na raiz):

| Variável | Descrição |
|---|---|
| `JWT_SECRET` | Chave secreta para assinatura dos tokens JWT |
| `OPENAI_API_KEY` | Chave da API OpenAI (necessária para geração de questões) |

### App Flutter

```bash
cd frontendFlutter
flutter pub get
flutter run
```

Por padrão o app aponta para `http://10.0.2.2` (emulador Android). Para dispositivo físico ou web, edite `lib/core/constants.dart`.

---

## Comunicação assíncrona (RabbitMQ)

Quando um aluno responde uma questão, o serviço `exercicios` publica um evento na exchange `exercicio.eventos` (tipo `fanout`). Esse evento é consumido por:

- **`alunos`**: atualiza o XP do aluno (+10 se acertou)
- **`trilhas`**: avança a fase atual do aluno na trilha

O publisher e os consumers ficam em tarefas assíncronas com `asyncio`, reconectando automaticamente se o RabbitMQ ainda estiver inicializando. Isso desacopla o registro de resposta do cálculo de progresso.

```
exercicios  ──publishes──►  exercicio.eventos (fanout exchange)
                                    ├──► fila anônima → alunos (atualiza XP)
                                    └──► fila anônima → trilhas (avança fase)
```

---

## Monitoramento

O projeto está preparado para Prometheus + Grafana, mas os containers foram removidos do `docker-compose.yml` por limitação de memória RAM na máquina de desenvolvimento.

Cada serviço FastAPI tem o `prometheus-fastapi-instrumentator` instalado e instrumentado, expondo métricas em `/metrics`. O arquivo `monitoring/prometheus.yml` e o dashboard JSON do Grafana estão em `monitoring/` para uso em ambiente com recursos suficientes.

Para ativar o monitoramento, descomentar os serviços `prometheus` e `grafana` no `docker-compose.yml` e subir novamente.

---

## CI/CD (GitHub Actions)

O pipeline está definido em `.github/workflows/ci.yml` e executa em dois estágios:

### 1. Testes (`test`)

Roda em paralelo para cada serviço usando matrix strategy:

```yaml
strategy:
  matrix:
    service: [auth, alunos, exercicios, trilhas, conteudos]
  fail-fast: false
```

Cada serviço tem seu próprio `test_main.py` com pytest. Os testes rodam sem Docker — o banco SQLite usa um caminho de fallback local detectado via `os.path.exists("/app/data")`.

### 2. Build e push (`build` → `push`)

As imagens são buildadas e publicadas no GitHub Container Registry (GHCR) apenas quando há push na branch `main`.

**Detalhe importante:** o Docker exige que o nome da imagem seja todo em minúsculas. O nome do usuário GitHub (`Deborange`) tem letra maiúscula, então o pipeline converte explicitamente:

```yaml
- name: Calcular prefixo da imagem (lowercase)
  run: echo "IMAGE_PREFIX=ghcr.io/$(echo '${{ github.repository_owner }}' | tr '[:upper:]' '[:lower:]')/historia" >> $GITHUB_ENV
```

---

## Dificuldades e lições aprendidas

### Limitação de memória e disco

A maior dificuldade prática foi a escassez de recursos na máquina de desenvolvimento (Windows com WSL). O Docker armazena dados em arquivos VHD (`ext4.vhdx`) que crescem com cada build e nunca diminuem automaticamente. Em determinado ponto, o disco encheu completamente durante um `docker pull`, corrompendo um arquivo de teste que estava sendo editado (truncou para vazio).

A solução foi desligar o WSL (`wsl --shutdown`) e deletar manualmente os arquivos VHD, liberando ~4 GB. Prometheus e Grafana foram removidos do compose por conta disso.

### CI/CD na prática

O GitHub Actions revelou divergências que passavam despercebidas localmente:

- **Caminhos de banco**: os testes de CI não têm `/app/data`, mas os containers Docker sempre têm. A solução foi detectar o ambiente via `os.path.exists` em vez de usar variáveis de ambiente ou mocks.
- **Mocks no pytest**: `@patch('app.ai_client.gerar_questoes')` não intercepta chamadas se `main.py` importa a função diretamente (`from app.ai_client import gerar_questoes`). O patch deve ser aplicado onde a função é *usada*, não onde é *definida*: `@patch('app.main.gerar_questoes')`.
- **Nome de imagem**: o Docker Registry rejeita nomes com letras maiúsculas. O nome do usuário (`Deborange`) precisou ser convertido explicitamente com `tr`.
- **CORS em preflight**: o Nginx precisou de blocos `if ($request_method = OPTIONS)` em cada `location`, porque `add_header` dentro de `if` não herda headers externos. O flag `always` também é necessário para incluir os headers em respostas de erro.

### Autenticação no Flutter

O modelo `Usuario.fromJson` tentava ler o campo `email` como `String` não-nulável, mas o endpoint `/auth/login` não retornava esse campo. O Flutter lançava um erro de tipo (`null is not String`) que aparecia como "erro no servidor" para o usuário. A correção exigiu adicionar `email` ao response do backend e garantir que `/auth/me` também o retornasse.
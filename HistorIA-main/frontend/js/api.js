const API = {
  auth:      "/auth",
  alunos:    "/alunos",
  trilhas:   "/trilhas",
  exercicios:"/exercicios",
  conteudos: "/conteudos"
};

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Cabeçalhos para requisições públicas (sem autenticação) */
function jsonHeaders() {
  return { "Content-Type": "application/json" };
}

/**
 * Cabeçalhos para requisições autenticadas.
 * Injeta o Bearer token salvo pelo state.js.
 */
function authHeaders() {
  return {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${getToken()}`
  };
}

// ── AUTH (rotas públicas — sem token) ─────────────────────────────────────────

async function loginApi(email, senha) {
  const res = await fetch(`${API.auth}/login`, {
    method: "POST",
    headers: jsonHeaders(),
    body: JSON.stringify({ email, senha })
  });
  return res.json();
}

async function registerApi(nome, email, senha, tipo) {
  const res = await fetch(`${API.auth}/registrar`, {
    method: "POST",
    headers: jsonHeaders(),
    body: JSON.stringify({ nome, email, senha, tipo })
  });
  return res.json();
}

// ── ALUNOS ───────────────────────────────────────────────────────────────────

async function listarAlunos() {
  const res = await fetch(`${API.alunos}/`, {
    headers: authHeaders()
  });
  return res.json();
}

async function criarAluno(nome, email) {
  const res = await fetch(`${API.alunos}/`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ nome, email })
  });
  return res.json();
}

async function obterAluno(id) {
  const res = await fetch(`${API.alunos}/${id}`, {
    headers: authHeaders()
  });
  return res.json();
}

async function atualizarAluno(id, dados) {
  const res = await fetch(`${API.alunos}/${id}`, {
    method: "PUT",
    headers: authHeaders(),
    body: JSON.stringify(dados)
  });
  return res.json();
}

async function deletarAluno(id) {
  const res = await fetch(`${API.alunos}/${id}`, {
    method: "DELETE",
    headers: authHeaders()
  });
  return res.json();
}

// ── TRILHAS ──────────────────────────────────────────────────────────────────

async function listarTrilhas() {
  const res = await fetch(`${API.trilhas}/`, {
    headers: authHeaders()
  });
  return res.json();
}

async function obterTrilha(id) {
  const res = await fetch(`${API.trilhas}/${id}`, {
    headers: authHeaders()
  });
  return res.json();
}

async function criarTrilha(nome, professor_id) {
  const res = await fetch(`${API.trilhas}/`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ nome, professor_id })
  });
  return res.json();
}

async function deletarTrilha(id) {
  const res = await fetch(`${API.trilhas}/${id}`, {
    method: "DELETE",
    headers: authHeaders()
  });
  return res.json();
}

// ── FASES ────────────────────────────────────────────────────────────────────

async function criarFase(trilha_id, nome, ordem) {
  const res = await fetch(`${API.trilhas}/fases`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ trilha_id, nome, ordem })
  });
  return res.json();
}

async function listarFases(trilha_id) {
  const res = await fetch(`${API.trilhas}/${trilha_id}/fases`, {
    headers: authHeaders()
  });
  return res.json();
}

// ── PROGRESSO ────────────────────────────────────────────────────────────────

async function iniciarTrilha(aluno_id, trilha_id) {
  const res = await fetch(`${API.trilhas}/progresso`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ aluno_id, trilha_id })
  });
  return res.json();
}

async function obterProgresso(aluno_id, trilha_id) {
  const res = await fetch(`${API.trilhas}/progresso/${aluno_id}/${trilha_id}`, {
    headers: authHeaders()
  });
  return res.json();
}

// ── EXERCÍCIOS ───────────────────────────────────────────────────────────────

async function gerarQuestoes(tema, quantidade) {
  const res = await fetch(`${API.exercicios}/gerar`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ tema, quantidade })
  });
  return res.json();
}

async function jogarExercicio(aluno_id, pergunta, resposta_usuario, resposta_correta, opcoes, trilha_id) {
  const res = await fetch(`${API.exercicios}/jogar`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({
      aluno_id,
      pergunta,
      resposta_usuario,
      resposta_correta,
      opcoes,
      trilha_id
    })
  });
  return res.json();
}

async function obterHistorico(aluno_id) {
  const res = await fetch(`${API.exercicios}/historico/${aluno_id}`, {
    headers: authHeaders()
  });
  return res.json();
}

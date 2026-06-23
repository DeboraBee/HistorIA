// ============ INICIALIZAÇÃO ============
async function inicializar() {
  requireAuth();

  const usuario = getUsuario();
  document.getElementById("userName").textContent = `👨‍🎓 ${usuario.nome}`;

  await sincronizarXP();
  carregarTrilhas();
  carregarHistorico();
}

async function sincronizarXP() {
  const usuario = getUsuario();
  try {
    const res = await obterAluno(usuario.id);
    if (res.success) {
      document.getElementById("userXP").textContent = res.data.xp ?? 0;
    }
  } catch (e) {
    console.error("Erro ao sincronizar XP:", e);
  }
}

// btn é o elemento clicado — opcional quando chamado programaticamente
function mostrarAba(aba, btn) {
  document.querySelectorAll(".tab-content").forEach(el => el.classList.remove("active"));
  document.querySelectorAll(".tab-button").forEach(el => el.classList.remove("active"));
  document.getElementById(aba).classList.add("active");
  if (btn) btn.classList.add("active");
}

function mostrarAlerta(msg, tipo) {
  const alert = document.getElementById("alert");
  alert.textContent = msg;
  alert.className = `alert show alert-${tipo}`;
  setTimeout(() => alert.classList.remove("show"), 4000);
}

// ============ TRILHAS ============
let trilhaAtualId   = null;
let trilhaAtualNome = null;
let faseAtualId     = null;
let faseAtualNome   = null;
let faseAtual       = 0;
let totalFases      = 0;
let questaoAtual    = 0;   // contador de questões dentro da fase
const QUESTOES_POR_FASE = 3;

async function carregarTrilhas() {
  try {
    const res = await listarTrilhas();

    if (!res.success) {
      mostrarAlerta("❌ Erro ao carregar trilhas", "error");
      return;
    }

    const container = document.getElementById("listaTrilhas");
    container.innerHTML = "";

    if (res.data.length === 0) {
      container.innerHTML = "<p style='text-align:center;color:#718096;grid-column:1/-1;'>Nenhuma trilha disponível no momento.</p>";
      return;
    }

    res.data.forEach(trilha => {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <h3 style="margin:0 0 1rem 0;color:#2d3748;">${trilha.nome}</h3>
        <p style="margin:0 0 1rem 0;color:#718096;font-size:0.9rem;">Aprenda ${trilha.nome}</p>
        <button class="btn btn-primary" onclick="entrarTrilha(${trilha.id}, '${trilha.nome}')">
          🚀 Entrar na Trilha
        </button>
      `;
      container.appendChild(card);
    });
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

async function entrarTrilha(trilhaId, trilhaNome) {
  const usuario = getUsuario();

  try {
    // Tenta iniciar — 400 "já está" é esperado e tratado
    let progressoData;
    const resIniciar = await iniciarTrilha(usuario.id, trilhaId);

    if (resIniciar.success) {
      const resProg = await obterProgresso(usuario.id, trilhaId);
      if (!resProg.success) { mostrarAlerta("❌ Erro ao obter progresso", "error"); return; }
      progressoData = resProg.data;
    } else {
      // Qualquer 4xx que não seja "já está" é erro real
      const detail = resIniciar.detail || "";
      if (!detail.includes("já está") && !detail.includes("já está")) {
        mostrarAlerta(`❌ ${detail || "Erro ao iniciar trilha"}`, "error");
        return;
      }
      const resProg = await obterProgresso(usuario.id, trilhaId);
      if (!resProg.success) { mostrarAlerta("❌ Erro ao obter progresso", "error"); return; }
      progressoData = resProg.data;
    }

    const resFases = await listarFases(trilhaId);
    if (!resFases.success || resFases.data.length === 0) {
      mostrarAlerta("❌ Esta trilha ainda não tem fases", "error");
      return;
    }

    trilhaAtualId   = trilhaId;
    trilhaAtualNome = trilhaNome;
    faseAtualId     = progressoData.fase_atual;
    totalFases      = resFases.data.length;

    const faseObj = resFases.data.find(f => f.id === faseAtualId) || resFases.data[0];
    faseAtual     = resFases.data.indexOf(faseObj) + 1;
    faseAtualNome = faseObj.nome;
    questaoAtual  = 1;

    document.getElementById("semTrilha").style.display          = "none";
    document.getElementById("exercicioContainer").style.display = "block";
    document.getElementById("trilhaTitulo").textContent         = `📚 ${trilhaNome}`;
    document.getElementById("faseAtual").textContent            = faseAtual;
    document.getElementById("fasesTotal").textContent           = totalFases;

    atualizarContadorQuestao();
    carregarQuestao();

    // Ativa aba sem depender de event
    mostrarAba("exercicio");
    const btnExercicio = document.querySelector(".tab-button[onclick*='exercicio']");
    if (btnExercicio) {
      document.querySelectorAll(".tab-button").forEach(b => b.classList.remove("active"));
      btnExercicio.classList.add("active");
    }
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

function atualizarContadorQuestao() {
  const el = document.getElementById("questaoAtual");
  const elTotal = document.getElementById("questoesTotal");
  if (el) el.textContent = questaoAtual;
  if (elTotal) elTotal.textContent = QUESTOES_POR_FASE;
}

// ============ EXERCÍCIOS ============
let questaoObj      = null;
let respostaUsuario = null;

async function carregarQuestao() {
  try {
    const tema = faseAtualNome || trilhaAtualNome || "história";
    const res  = await gerarQuestoes(tema, 1);

    if (!res.success || !res.data?.length) {
      mostrarAlerta("❌ Erro ao carregar questão", "error");
      return;
    }

    questaoObj      = res.data[0];
    respostaUsuario = null;

    document.getElementById("pergunta").textContent = questaoObj.pergunta;

    const opcoesDiv = document.getElementById("opcoes");
    opcoesDiv.innerHTML = "";
    questaoObj.opcoes.forEach((opcao, idx) => {
      const btn = document.createElement("button");
      btn.className = "btn btn-secondary";
      btn.textContent = opcao;
      btn.onclick = () => selecionarOpcao(idx);
      opcoesDiv.appendChild(btn);
    });

    document.getElementById("feedback").classList.remove("show");
    document.getElementById("btnProxima").style.display  = "none";
    document.getElementById("btnConcluir").style.display = "none";
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

function selecionarOpcao(idx) {
  respostaUsuario = idx;

  document.querySelectorAll("#opcoes .btn").forEach((btn, i) => {
    btn.classList.toggle("btn-primary",   i === idx);
    btn.classList.toggle("btn-secondary", i !== idx);
  });

  verificarResposta();
}

async function verificarResposta() {
  const usuario = getUsuario();
  const acertou = respostaUsuario === questaoObj.resposta_correta;

  try {
    const res = await jogarExercicio(
      usuario.id,
      questaoObj.pergunta,
      respostaUsuario,
      questaoObj.resposta_correta,
      questaoObj.opcoes,
      trilhaAtualId
    );

    if (!res.success) {
      mostrarAlerta(`❌ ${res.detail || "Erro"}`, "error");
      return;
    }

    // Feedback
    const feedback     = document.getElementById("feedback");
    const feedbackText = document.getElementById("feedbackTexto");
    if (acertou) {
      feedback.className       = "alert show alert-success";
      feedbackText.textContent = `✅ Acertou! +10 XP`;
    } else {
      feedback.className       = "alert show alert-error";
      feedbackText.textContent = `❌ Errou! Resposta correta: ${questaoObj.opcoes[questaoObj.resposta_correta]}`;
    }

    document.querySelectorAll("#opcoes .btn").forEach(btn => { btn.disabled = true; });

    // Última questão da fase?
    const ultimaQuestao = questaoAtual >= QUESTOES_POR_FASE;
    const ultimaFase    = faseAtual >= totalFases;

    if (ultimaQuestao && ultimaFase) {
      document.getElementById("btnConcluir").style.display = "block";
    } else {
      document.getElementById("btnProxima").style.display = "block";
    }

    await sincronizarXP();
    carregarHistorico();
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

function proximaQuestao() {
  questaoAtual++;

  // Passou de QUESTOES_POR_FASE → avança fase
  if (questaoAtual > QUESTOES_POR_FASE) {
    faseAtual++;
    questaoAtual = 1;
    mostrarAlerta(`🎯 Fase ${faseAtual} iniciada!`, "success");
    document.getElementById("faseAtual").textContent = faseAtual;
  }

  atualizarContadorQuestao();
  carregarQuestao();
}

function concluirFase() {
  mostrarAlerta("🎉 Parabéns! Você completou a trilha!", "success");
  document.getElementById("exercicioContainer").style.display = "none";
  document.getElementById("semTrilha").style.display          = "block";
  carregarTrilhas();
  mostrarAba("trilhas");
  const btnTrilhas = document.querySelector(".tab-button[onclick*='trilhas']");
  if (btnTrilhas) {
    document.querySelectorAll(".tab-button").forEach(b => b.classList.remove("active"));
    btnTrilhas.classList.add("active");
  }
}

// ============ HISTÓRICO ============
async function carregarHistorico() {
  const usuario = getUsuario();
  try {
    const res = await obterHistorico(usuario.id);
    const tbody = document.getElementById("tabelaHistorico");

    if (!res.success || res.data.length === 0) {
      tbody.innerHTML = `
        <tr>
          <td colspan="3" style="text-align:center;padding:2rem;color:#718096;">
            Nenhum histórico ainda
          </td>
        </tr>`;
      return;
    }

    tbody.innerHTML = "";
    res.data.forEach(item => {
      const tr = document.createElement("tr");
      tr.style.borderBottom = "1px solid #e2e8f0";
      tr.innerHTML = `
        <td style="padding:1rem;border-right:1px solid #e2e8f0;">${item.pergunta.substring(0, 50)}…</td>
        <td style="padding:1rem;border-right:1px solid #e2e8f0;">${item.acertou ? "✅ Acertou" : "❌ Errou"}</td>
        <td style="padding:1rem;text-align:center;">${item.acertou ? "+10" : "0"} XP</td>
      `;
      tbody.appendChild(tr);
    });
  } catch (erro) {
    console.error("Erro ao carregar histórico:", erro);
  }
}

// ============ LOGOUT ============
function fazerLogout() {
  if (confirm("Deseja sair?")) logout();
}

inicializar();
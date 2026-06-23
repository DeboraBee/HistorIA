// ============ INICIALIZAÇÃO ============
async function inicializar() {
  requireAuth();

  const usuario = getUsuario();
  document.getElementById("userName").textContent = `👨‍🏫 ${usuario.nome}`;

  carregarAlunos();
  carregarTrilhas();
  carregarTrilhasParaExercicios();
}

function mostrarAba(aba) {
  document.querySelectorAll(".tab-content").forEach(el => el.classList.remove("active"));
  document.querySelectorAll(".tab-button").forEach(el => el.classList.remove("active"));
  document.getElementById(aba).classList.add("active");
  event.target.classList.add("active");

  if (aba === "historico") carregarHistorico();
}

function mostrarAlerta(msg, tipo) {
  const alert = document.getElementById("alert");
  alert.textContent = msg;
  alert.className = `alert show alert-${tipo}`;
  setTimeout(() => alert.classList.remove("show"), 4000);
}

// ============ ALUNOS ============
async function carregarAlunos() {
  try {
    const res = await listarAlunos();

    if (!res.success) {
      mostrarAlerta(`❌ Erro ao carregar alunos: ${res.detail}`, "error");
      return;
    }

    const container = document.getElementById("listaAlunos");
    container.innerHTML = "";

    if (res.data.length === 0) {
      container.innerHTML = "<p style='text-align:center;color:#718096;grid-column:1/-1;'>Nenhum aluno cadastrado.</p>";
      return;
    }

    res.data.forEach(aluno => {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <div style="display:flex;justify-content:space-between;align-items:start;">
          <div>
            <h3 style="margin:0 0 0.5rem 0;color:#2d3748;">${aluno.nome}</h3>
            <p style="margin:0 0 1rem 0;color:#718096;font-size:0.9rem;">${aluno.email}</p>
            <p style="margin:0;color:#4a5568;font-size:0.9rem;">⭐ ${aluno.xp ?? 0} XP</p>
          </div>
        </div>
        <div class="btn-group" style="margin-top:1rem;">
          <button class="btn btn-secondary btn-small" onclick="editarAluno(${aluno.id}, '${aluno.nome}', '${aluno.email}')">✏️ Editar</button>
          <button class="btn btn-danger btn-small" onclick="confirmarDeletar(${aluno.id}, 'aluno', '${aluno.nome}')">🗑️ Deletar</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

function abrirModalAluno() {
  document.getElementById("nomeAluno").value  = "";
  document.getElementById("emailAluno").value = "";
  document.getElementById("modalAluno").classList.add("show");
}

// Nomes distintos das funções do api.js (criarAluno, deletarAluno)
async function submeterCriarAluno() {
  const nome  = document.getElementById("nomeAluno").value.trim();
  const email = document.getElementById("emailAluno").value.trim();

  if (!nome || !email) {
    mostrarAlerta("❌ Preencha todos os campos", "error");
    return;
  }

  try {
    const res = await criarAluno(nome, email);  // chama api.js

    if (!res.success) {
      mostrarAlerta(`❌ ${res.detail || "Erro ao criar aluno"}`, "error");
      return;
    }

    mostrarAlerta("✅ Aluno criado com sucesso!", "success");
    fecharModal("modalAluno");
    carregarAlunos();
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

async function editarAluno(id, nome, email) {
  const novoNome = prompt("Novo nome:", nome);
  if (novoNome === null || !novoNome.trim()) return;

  try {
    const res = await atualizarAluno(id, { nome: novoNome.trim() });

    if (!res.success) {
      mostrarAlerta(`❌ ${res.detail || "Erro ao atualizar"}`, "error");
      return;
    }

    mostrarAlerta("✅ Aluno atualizado!", "success");
    carregarAlunos();
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

async function submeterDeletarAluno(id) {
  try {
    const res = await deletarAluno(id);  // chama api.js

    if (!res.success) {
      mostrarAlerta(`❌ ${res.detail || "Erro ao deletar"}`, "error");
      return;
    }

    mostrarAlerta("✅ Aluno deletado!", "success");
    carregarAlunos();
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

// ============ TRILHAS ============
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
      container.innerHTML = "<p style='text-align:center;color:#718096;grid-column:1/-1;'>Nenhuma trilha criada ainda.</p>";
      return;
    }

    res.data.forEach(trilha => {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <h3 style="margin:0 0 1rem 0;color:#2d3748;">${trilha.nome}</h3>
        <p style="margin:0 0 1rem 0;color:#718096;font-size:0.9rem;">ID: ${trilha.id}</p>
        <div class="btn-group">
          <button class="btn btn-secondary btn-small" onclick="selecionarTrilhaParaFases(${trilha.id}, '${trilha.nome}')">📋 Fases</button>
          <button class="btn btn-danger btn-small" onclick="confirmarDeletar(${trilha.id}, 'trilha', '${trilha.nome}')">🗑️ Deletar</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

async function carregarTrilhasParaExercicios() {
  try {
    const res = await listarTrilhas();
    if (!res.success) return;

    const select = document.getElementById("temaTrilha");
    select.innerHTML = '<option value="">Escolha uma trilha...</option>';

    res.data.forEach(trilha => {
      const opt = document.createElement("option");
      opt.value = trilha.id;
      opt.textContent = trilha.nome;
      select.appendChild(opt);
    });
  } catch (erro) {
    console.error(erro);
  }
}

function abrirModalTrilha() {
  document.getElementById("nomeTrilha").value = "";
  document.getElementById("listaFases").innerHTML = "";
  faseInputCount = 0;
  adicionarFaseInput();
  document.getElementById("modalTrilha").classList.add("show");
}

let faseInputCount = 0;

function adicionarFaseInput() {
  faseInputCount++;
  const div = document.createElement("div");
  div.className = "form-group";
  div.style.marginBottom = "1rem";
  div.innerHTML = `
    <div style="display:grid;grid-template-columns:1fr 100px;gap:0.5rem;">
      <input type="text" placeholder="Nome da fase" class="faseNome">
      <input type="number" placeholder="Ordem" min="1" value="${faseInputCount}" class="faseOrdem" style="width:100%;">
    </div>
    <button class="btn btn-secondary btn-small" type="button"
      onclick="this.parentElement.remove()" style="margin-top:0.5rem;width:100%;">
      Remover
    </button>
  `;
  document.getElementById("listaFases").appendChild(div);
}

async function submeterCriarTrilha() {
  const usuario = getUsuario();
  const nome    = document.getElementById("nomeTrilha").value.trim();

  if (!nome) {
    mostrarAlerta("❌ Digite o nome da trilha", "error");
    return;
  }

  try {
    const resTrilha = await criarTrilha(nome, usuario.id);  // chama api.js

    if (!resTrilha.success) {
      mostrarAlerta(`❌ ${resTrilha.detail || "Erro ao criar trilha"}`, "error");
      return;
    }

    const trilhaId    = resTrilha.data.id;
    const faseInputs  = document.querySelectorAll("#listaFases .form-group");

    for (const input of faseInputs) {
      const nomeFase = input.querySelector(".faseNome").value.trim();
      const ordem    = parseInt(input.querySelector(".faseOrdem").value);

      if (!nomeFase) continue;

      const resFase = await criarFase(trilhaId, nomeFase, ordem);
      if (!resFase.success) {
        console.error("Erro ao criar fase:", resFase.detail);
      }
    }

    mostrarAlerta("✅ Trilha e fases criadas com sucesso!", "success");
    fecharModal("modalTrilha");
    carregarTrilhas();
    carregarTrilhasParaExercicios();
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

function selecionarTrilhaParaFases(trilhaId, trilhaNome) {
  mostrarAlerta(`📋 Trilha "${trilhaNome}" selecionada. Vá à aba Exercícios para adicionar conteúdo.`, "info");
}

async function atualizarFases() {
  const trilhaId = document.getElementById("temaTrilha").value;

  if (!trilhaId) {
    document.getElementById("faseSelecionada").innerHTML = '<option value="">Escolha uma fase...</option>';
    return;
  }

  try {
    const res = await listarFases(trilhaId);

    if (!res.success) {
      document.getElementById("faseSelecionada").innerHTML = '<option value="">Nenhuma fase encontrada</option>';
      return;
    }

    const select = document.getElementById("faseSelecionada");
    select.innerHTML = '<option value="">Escolha uma fase...</option>';

    res.data.forEach(fase => {
      const opt = document.createElement("option");
      opt.value = fase.id;
      opt.textContent = `${fase.nome} (Ordem: ${fase.ordem})`;
      select.appendChild(opt);
    });
  } catch (erro) {
    console.error(erro);
  }
}

// ============ EXERCÍCIOS COM IA ============
async function gerarExerciciosIA() {
  const tema       = document.getElementById("temaIA").value.trim();
  const quantidade = parseInt(document.getElementById("quantidadeQuestoes").value);
  const trilhaId   = document.getElementById("temaTrilha").value;
  const faseId     = document.getElementById("faseSelecionada").value;

  if (!tema)              { mostrarAlerta("❌ Digite um tema", "error"); return; }
  if (!trilhaId || !faseId) { mostrarAlerta("❌ Selecione trilha e fase", "error"); return; }

  try {
    const res = await gerarQuestoes(tema, quantidade);

    if (!res.success) {
      mostrarAlerta(`❌ ${res.detail || "Erro ao gerar questões"}`, "error");
      return;
    }

    const container = document.getElementById("questoesGeradas");
    container.innerHTML = "";

    res.data.forEach((questao, idx) => {
      const div = document.createElement("div");
      div.className = "card";
      div.style.marginBottom = "1rem";
      div.innerHTML = `
        <h4 style="margin:0 0 1rem 0;">Questão ${idx + 1}</h4>
        <p><strong>Pergunta:</strong> ${questao.pergunta}</p>
        <p><strong>Opções:</strong></p>
        <ol style="margin:0.5rem 0 1rem 1.5rem;">
          ${questao.opcoes.map((op, i) => `<li>${op} ${i === questao.resposta_correta ? "✅" : ""}</li>`).join("")}
        </ol>
        <p><strong>Resposta Correta:</strong> Opção ${questao.resposta_correta + 1}</p>
      `;
      container.appendChild(div);
    });

    document.getElementById("resultadoIA").style.display = "block";
    mostrarAlerta("✅ Questões geradas com sucesso!", "success");
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

// ============ MODAIS E UTILITÁRIOS ============
function fecharModal(modalId) {
  document.getElementById(modalId).classList.remove("show");
}

function confirmarDeletar(id, tipo, nome) {
  const label = tipo === "aluno" ? "o aluno" : "a trilha";
  if (!confirm(`Tem certeza que deseja deletar ${label} "${nome}"?\n\nEsta ação não pode ser desfeita!`)) return;

  if (tipo === "aluno") {
    submeterDeletarAluno(id);
  } else {
    submeterDeletarTrilha(id);
  }
}

async function submeterDeletarTrilha(id) {
  try {
    const res = await deletarTrilha(id);  // chama api.js

    if (!res.success) {
      mostrarAlerta(`❌ ${res.detail || "Erro ao deletar"}`, "error");
      return;
    }

    mostrarAlerta("✅ Trilha deletada!", "success");
    carregarTrilhas();
    carregarTrilhasParaExercicios();
  } catch (erro) {
    mostrarAlerta(`❌ Erro: ${erro.message}`, "error");
  }
}

// Fechar modal clicando fora
document.addEventListener("click", e => {
  if (e.target.classList.contains("modal")) {
    e.target.classList.remove("show");
  }
});

// ============ LOGOUT ============
function fazerLogout() {
  if (confirm("Deseja sair?")) logout();  // logout() vem do state.js
}

// Inicializar ao carregar
inicializar();
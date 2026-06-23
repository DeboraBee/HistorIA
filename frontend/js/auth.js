// ============ LOGIN ============
async function login() {
  const email = document.getElementById("email").value.trim();
  const senha = document.getElementById("senha").value;

  if (!email || !senha) {
    alert("Preencha email e senha");
    return;
  }

  const data = await loginApi(email, senha);

  if (!data.success) {
    alert(data.detail || "Erro no login");
    return;
  }

  // Salva usuário e token JWT juntos
  setUsuario(data.data, data.token);

  if (data.data.tipo === "professor") {
    window.location.href = "/professor.html";
  } else {
    window.location.href = "/aluno.html";
  }
}

// ============ REGISTRO ============
async function register() {
  const nome  = document.getElementById("nome").value.trim();
  const email = document.getElementById("email").value.trim();
  const senha = document.getElementById("senha").value;
  const tipo  = document.getElementById("tipo").value;

  if (!nome || !email || !senha || !tipo) {
    alert("Preencha todos os campos");
    return;
  }

  const data = await registerApi(nome, email, senha, tipo);

  if (!data.success) {
    alert(data.detail || "Erro no cadastro");
    return;
  }

  alert("Conta criada! Faça login para continuar.");
  window.location.href = "/login.html";
}

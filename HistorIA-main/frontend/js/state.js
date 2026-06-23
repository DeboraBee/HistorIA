// ============ STATE ============
let state = {
  usuario: JSON.parse(localStorage.getItem("usuario") || "null"),
  token: localStorage.getItem("token") || null
};

function setUsuario(user, token) {
  state.usuario = user;
  state.token = token;
  localStorage.setItem("usuario", JSON.stringify(user));
  localStorage.setItem("token", token);
}

function getToken() {
  return state.token;
}

function getUsuario() {
  return state.usuario;
}

function logout() {
  state.usuario = null;
  state.token = null;
  localStorage.removeItem("usuario");
  localStorage.removeItem("token");
  window.location.href = "/login.html";
}

function requireAuth() {
  if (!state.usuario || !state.token) {
    window.location.href = "/login.html";
  }
}

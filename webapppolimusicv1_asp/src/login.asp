<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  login.asp  -  Inicio de sesion
' =====================================================================
Dim usuario, clave, mensajeError, nextUrl, dest

mensajeError = ""
nextUrl = CStr(Request.QueryString("next") & "")

If IsLoggedIn() Then
  Response.Redirect Url("index.asp")
  Response.End
End If

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
  usuario = Trim(CStr(Request.Form("usuario") & ""))
  clave   = CStr(Request.Form("clave") & "")
  nextUrl = CStr(Request.Form("next") & "")

  If Len(usuario) = 0 Or Len(clave) = 0 Then
    mensajeError = "Ingresa tu usuario y tu contrasena."
  ElseIf DoLogin(usuario, clave) Then
    SetFlash "Bienvenido de vuelta, " & UserName() & ".", "ok"
    dest = SafeRedirect(nextUrl, Url("index.asp"))
    ' Si el destino era una pagina del iframe, se reconstruye la URL del shell
    If InStr(LCase(dest), "f=1") > 0 Then
      Dim rel
      rel = Mid(dest, Len(AppRoot()) + 1)
      rel = Replace(rel, "?f=1", "")
      rel = Replace(rel, "&f=1", "")
      rel = Replace(rel, "f=1&", "")
      If Len(Trim(rel)) = 0 Then rel = "home.asp"
      dest = Url("index.asp") & "?p=" & U(rel)
    End If
    Response.Redirect dest
    Response.End
  Else
    mensajeError = "Usuario o contrasena incorrectos. Verifica tus datos."
  End If
End If

RenderStandaloneTop "Iniciar sesion"
%>
<div class="auth">

  <section class="auth-art">
    <div class="auth-logo">
      <span class="brand-mark"><%=Icon("music")%></span>
      <strong><%=H(APP_NAME)%></strong>
    </div>
    <h2>Tu musica, tus playlists, tus artistas.</h2>
    <p>Plataforma de streaming musical de la <%=H(APP_SUBTITLE)%>. Escucha, organiza y comparte tu catalogo.</p>
    <div class="auth-feats">
      <div class="auth-feat"><%=Icon("song")%><span>Catalogo completo de canciones, albumes y artistas</span></div>
      <div class="auth-feat"><%=Icon("playlist")%><span>Crea y administra tus propias playlists</span></div>
      <div class="auth-feat"><%=Icon("lock")%><span>Playlists publicas o privadas</span></div>
      <div class="auth-feat"><%=Icon("users")%><span>Roles de administrador y usuario</span></div>
    </div>
  </section>

  <section class="auth-panel">
    <div class="auth-box">
      <h1>Iniciar sesion</h1>
      <p class="sub">Accede con tu cuenta para escuchar tu musica.</p>

<% If Len(mensajeError) > 0 Then %>
      <div class="alert"><%=H(mensajeError)%></div>
<% End If %>

      <form method="post" action="<%=Url("login.asp")%>" autocomplete="off">
        <input type="hidden" name="next" value="<%=H(nextUrl)%>">

        <div class="field">
          <label for="usuario">Usuario</label>
          <input class="input" type="text" id="usuario" name="usuario" maxlength="50"
                 value="<%=H(usuario)%>" placeholder="Tu nombre de usuario" required autofocus>
        </div>

        <div class="field">
          <label for="clave">Contrasena</label>
          <input class="input" type="password" id="clave" name="clave" maxlength="50"
                 placeholder="Tu contrasena" required>
        </div>

        <button class="btn btn-primary" type="submit"><%=Icon("logout")%>Entrar</button>
      </form>

      <div class="auth-alt">
        No tienes una cuenta? <a href="<%=Url("register.asp")%>">Registrate aqui</a>
      </div>

      <div class="cred-box">
        <strong>Cuentas de prueba</strong>
        Administrador: <code>userAdmin</code> / <code>12345678</code><br>
        Usuario normal: <code>userNormal</code> / <code>12345678</code>
      </div>
    </div>
  </section>

</div>
<%
RenderStandaloneBottom
CloseDb
%>

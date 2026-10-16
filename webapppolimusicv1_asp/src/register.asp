<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  register.asp  -  Registro / enrolamiento de usuarios
'  Los usuarios creados por esta via siempre son de tipo USUARIO (0).
' =====================================================================
Dim usuario, email, clave, clave2, cumple, foto, errores, ok, i
Dim existeUser, existeMail

errores = ""
usuario = ""
email   = ""
cumple  = ""

If IsLoggedIn() Then
  Response.Redirect Url("index.asp")
  Response.End
End If

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then

  usuario = Trim(FormVal("usuario"))
  email   = Trim(FormVal("email"))
  clave   = FormVal("clave")
  clave2  = FormVal("clave2")
  cumple  = Trim(FormVal("cumple"))

  ' ------------------------------ validaciones ----------------------
  If Len(usuario) < 3 Then
    errores = errores & "<li>El usuario debe tener al menos 3 caracteres.</li>"
  ElseIf Len(usuario) > 50 Then
    errores = errores & "<li>El usuario no puede superar los 50 caracteres.</li>"
  End If

  If Len(email) = 0 Or InStr(email, "@") = 0 Or InStr(email, ".") = 0 Then
    errores = errores & "<li>Ingresa un correo electronico valido.</li>"
  ElseIf Len(email) > 50 Then
    errores = errores & "<li>El correo no puede superar los 50 caracteres.</li>"
  End If

  If Len(clave) < 6 Then
    errores = errores & "<li>La contrasena debe tener al menos 6 caracteres.</li>"
  ElseIf Len(clave) > 50 Then
    errores = errores & "<li>La contrasena no puede superar los 50 caracteres.</li>"
  End If

  If clave <> clave2 Then
    errores = errores & "<li>Las contrasenas no coinciden.</li>"
  End If

  If Len(cumple) > 0 Then
    If Not IsDate(cumple) Then
      errores = errores & "<li>La fecha de nacimiento no es valida.</li>"
    ElseIf CDate(cumple) > Date() Then
      errores = errores & "<li>La fecha de nacimiento no puede ser futura.</li>"
    End If
  End If

  If Len(errores) = 0 Then
    existeUser = DbExists("SELECT 1 FROM TBL_USER WHERE USERNAME = " & Q(usuario))
    If existeUser Then
      errores = errores & "<li>El nombre de usuario <strong>" & H(usuario) & "</strong> ya esta en uso.</li>"
    End If
    existeMail = DbExists("SELECT 1 FROM TBL_USER WHERE EMAIL = " & Q(email))
    If existeMail Then
      errores = errores & "<li>El correo <strong>" & H(email) & "</strong> ya esta registrado.</li>"
    End If
  End If

  ' --------------------------- foto opcional ------------------------
  If Len(errores) = 0 Then
    foto = ""
    If HasUpload("foto") Then
      If UploadSize("foto") > UPLOAD_MAX_IMAGE Then
        errores = errores & "<li>La imagen supera el limite de 5 MB.</li>"
      Else
        foto = SaveUpload("foto", DIR_USER, EXT_IMAGE, UPLOAD_MAX_IMAGE, usuario)
        If Len(foto) = 0 And UploadSize("foto") > 0 Then
          errores = errores & "<li>El formato de la imagen no es valido (usa JPG, PNG, GIF o WEBP).</li>"
        End If
      End If
    End If
    If Len(foto) = 0 Then foto = "~/" & IMG_USER_DEF
  End If

  ' ------------------------------ guardar ---------------------------
  If Len(errores) = 0 Then
    DbExec "INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) VALUES (" & _
           Q(usuario) & ", " & Q(SHA1(clave)) & ", " & Q(email) & ", " & _
           DQ(IIfS(Len(cumple) > 0, cumple, "")) & ", " & Q(foto) & ", " & ROLE_USER & ")"

    SetFlash "Tu cuenta fue creada correctamente. Ya puedes iniciar sesion.", "ok"
    Response.Redirect Url("login.asp")
    Response.End
  End If

End If

RenderStandaloneTop "Crear cuenta"
%>
<div class="auth">

  <section class="auth-art">
    <div class="auth-logo">
      <span class="brand-mark"><%=Icon("music")%></span>
      <strong><%=H(APP_NAME)%></strong>
    </div>
    <h2>Crea tu cuenta y empieza a escuchar.</h2>
    <p>Registrarte es gratis. Tendras tu propia biblioteca de playlists y acceso a todo el catalogo.</p>
    <div class="auth-feats">
      <div class="auth-feat"><%=Icon("check")%><span>Reproduce canciones, albumes y artistas</span></div>
      <div class="auth-feat"><%=Icon("check")%><span>Crea, edita y elimina tus playlists</span></div>
      <div class="auth-feat"><%=Icon("check")%><span>Elige si tus playlists son publicas o privadas</span></div>
      <div class="auth-feat"><%=Icon("check")%><span>Personaliza tu foto de perfil</span></div>
    </div>
  </section>

  <section class="auth-panel">
    <div class="auth-box">
      <a class="auth-back" href="<%=Url("login.asp")%>"><%=Icon("back")%>Volver al inicio de sesion</a>

      <h1>Crear cuenta</h1>
      <p class="sub">Completa tus datos para registrarte en <%=H(APP_NAME)%>.</p>

<% If Len(errores) > 0 Then %>
      <div class="alert"><strong>Revisa lo siguiente:</strong><ul><%=errores%></ul></div>
<% End If %>

      <form method="post" action="<%=Url("register.asp")%>" enctype="multipart/form-data" autocomplete="off">

        <div class="field">
          <label for="usuario">Usuario <span class="req">*</span></label>
          <input class="input" type="text" id="usuario" name="usuario" maxlength="50"
                 value="<%=H(usuario)%>" placeholder="Minimo 3 caracteres" required>
        </div>

        <div class="field">
          <label for="email">Correo electronico <span class="req">*</span></label>
          <input class="input" type="email" id="email" name="email" maxlength="50"
                 value="<%=H(email)%>" placeholder="usuario@epn.edu.ec" required>
        </div>

        <div class="field">
          <label for="clave">Contrasena <span class="req">*</span></label>
          <input class="input" type="password" id="clave" name="clave" maxlength="50"
                 placeholder="Minimo 6 caracteres" required>
        </div>

        <div class="field">
          <label for="clave2">Repetir contrasena <span class="req">*</span></label>
          <input class="input" type="password" id="clave2" name="clave2" maxlength="50"
                 placeholder="Repite tu contrasena" required>
        </div>

        <div class="field">
          <label for="cumple">Fecha de nacimiento</label>
          <input class="input" type="date" id="cumple" name="cumple" value="<%=H(cumple)%>">
          <span class="hint">Opcional.</span>
        </div>

        <div class="field">
          <label for="foto">Foto de perfil</label>
          <input class="input" type="file" id="foto" name="foto" accept="image/*" data-preview="fotoPrev">
          <span class="hint">Opcional. JPG, PNG, GIF o WEBP hasta 5 MB.</span>
        </div>

        <div class="row" style="margin-top:6px">
          <img class="preview-thumb round" id="fotoPrev" src="<%=Url(IMG_USER_DEF)%>" alt="Vista previa">
          <span class="muted">Vista previa de tu foto</span>
        </div>

        <button class="btn btn-primary" type="submit"><%=Icon("user")%>Crear mi cuenta</button>
      </form>

      <div class="auth-alt">
        Ya tienes una cuenta? <a href="<%=Url("login.asp")%>">Inicia sesion</a>
      </div>
    </div>
  </section>

</div>
<%
RenderStandaloneBottom
CloseDb
%>

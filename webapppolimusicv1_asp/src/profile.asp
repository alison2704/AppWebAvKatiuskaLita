<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  profile.asp  -  Perfil del usuario conectado
'  Cualquier usuario puede editar sus propios datos.
' =====================================================================
RequireLogin
EnsureFrame

Dim rs, errores, usuario, email, cumple, foto, clave, claveActual, clave2, subida, accion

Set rs = DbRs("SELECT * FROM TBL_USER WHERE ID_USER = " & N(UserId()))
If rs.EOF Then
  rs.Close
  DoLogout
  Response.Redirect Url("login.asp")
  Response.End
End If

usuario = F(rs, "USERNAME")
email   = F(rs, "EMAIL")
cumple  = FormatDateInput(F(rs, "BIRTHDAY"))
foto    = F(rs, "USER_PHOTO")
If Len(foto) = 0 Then foto = "~/" & IMG_USER_DEF
rs.Close
Set rs = Nothing

errores = ""

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then

  usuario     = Trim(FormVal("usuario"))
  email       = Trim(FormVal("email"))
  cumple      = Trim(FormVal("cumple"))
  foto        = Trim(FormVal("imagen"))
  claveActual = FormVal("clave_actual")
  clave       = FormVal("clave")
  clave2      = FormVal("clave2")

  If Len(usuario) < 3 Then
    errores = errores & "<li>El usuario debe tener al menos 3 caracteres.</li>"
  ElseIf Len(usuario) > 50 Then
    errores = errores & "<li>El usuario no puede superar los 50 caracteres.</li>"
  End If

  If Len(email) = 0 Or InStr(email, "@") = 0 Then
    errores = errores & "<li>Ingresa un correo electronico valido.</li>"
  ElseIf Len(email) > 50 Then
    errores = errores & "<li>El correo no puede superar los 50 caracteres.</li>"
  End If

  If Len(cumple) > 0 Then
    If Not IsDate(cumple) Then
      errores = errores & "<li>La fecha de nacimiento no es valida.</li>"
    ElseIf CDate(cumple) > Date() Then
      errores = errores & "<li>La fecha de nacimiento no puede ser futura.</li>"
    End If
  End If

  If DbExists("SELECT 1 FROM TBL_USER WHERE USERNAME = " & Q(usuario) & " AND ID_USER <> " & N(UserId())) Then
    errores = errores & "<li>Ese nombre de usuario ya esta en uso.</li>"
  End If
  If DbExists("SELECT 1 FROM TBL_USER WHERE EMAIL = " & Q(email) & " AND ID_USER <> " & N(UserId())) Then
    errores = errores & "<li>Ese correo ya esta registrado.</li>"
  End If

  ' ---- cambio de contrasena -----------------------------------------
  If Len(clave) > 0 Then
    If DbExists("SELECT 1 FROM TBL_USER WHERE ID_USER = " & N(UserId()) & " AND UPPER(PASSWORD) = " & Q(SHA1(claveActual))) Then
      If Len(clave) < 6 Then
        errores = errores & "<li>La nueva contrasena debe tener al menos 6 caracteres.</li>"
      ElseIf clave <> clave2 Then
        errores = errores & "<li>La confirmacion de la contrasena no coincide.</li>"
      End If
    Else
      errores = errores & "<li>La contrasena actual no es correcta.</li>"
    End If
  End If

  ' ---- foto ---------------------------------------------------------
  subida = ""
  If HasUpload("foto") And UploadSize("foto") > 0 Then
    If UploadSize("foto") > UPLOAD_MAX_IMAGE Then
      errores = errores & "<li>La imagen supera el limite de 5 MB.</li>"
    Else
      subida = SaveUpload("foto", DIR_USER, EXT_IMAGE, UPLOAD_MAX_IMAGE, usuario)
      If Len(subida) = 0 Then
        errores = errores & "<li>El formato de la imagen no es valido (JPG, PNG, GIF o WEBP).</li>"
      End If
    End If
  End If
  If Len(subida) > 0 Then
    foto = subida
  ElseIf Len(foto) = 0 Then
    foto = "~/" & IMG_USER_DEF
  End If

  If Len(errores) = 0 Then
    Dim sql
    sql = "UPDATE TBL_USER SET USERNAME = " & Q(usuario) & _
          ", EMAIL = " & Q(email) & _
          ", BIRTHDAY = " & DQ(cumple) & _
          ", USER_PHOTO = " & Q(foto)
    If Len(clave) > 0 Then sql = sql & ", PASSWORD = " & Q(SHA1(clave))
    sql = sql & " WHERE ID_USER = " & N(UserId())
    DbExec sql

    Session("uname")  = usuario
    Session("uemail") = email
    Session("uphoto") = foto

    FlashRedirect "Tu perfil se actualizo correctamente.", "ok", "profile.asp"
  End If
End If

RenderFrameTop "Mi perfil", "profile", "Administra tu informacion personal y tu contrasena."
%>

<div class="stat-row">
  <div class="stat"><div class="k">Rol</div><div class="v"><%=H(RoleLabel(UserType()))%></div></div>
  <div class="stat"><div class="k">Mis playlists</div><div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = " & N(UserId()))%></div></div>
  <div class="stat"><div class="k">Playlists publicas</div><div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = " & N(UserId()) & " AND TYPE = " & PL_PUBLIC)%></div></div>
</div>

<% If Len(errores) > 0 Then %>
  <div class="alert"><strong>Revisa lo siguiente:</strong><ul><%=errores%></ul></div>
<% End If %>

<form class="form-card" method="post" action="<%=FUrl("profile.asp")%>" enctype="multipart/form-data">

  <div class="row mb-24">
    <img class="preview-thumb round" id="imgPrev" src="<%=H(ImgUser(foto))%>" alt="Foto de perfil" style="width:110px;height:110px">
    <div>
      <h2 style="font-size:20px"><%=H(usuario)%></h2>
      <p class="muted mb-0"><%=H(email)%></p>
      <span class="badge <%=IIfS(UserType() = ROLE_ADMIN, "badge-admin", "badge-user")%>" style="margin-top:8px">
        <%=H(RoleLabel(UserType()))%>
      </span>
    </div>
  </div>

  <div class="form-grid">
    <div class="field">
      <label for="usuario">Usuario <span class="req">*</span></label>
      <input class="input" type="text" id="usuario" name="usuario" maxlength="50" value="<%=H(usuario)%>" required>
    </div>

    <div class="field">
      <label for="email">Correo electronico <span class="req">*</span></label>
      <input class="input" type="email" id="email" name="email" maxlength="50" value="<%=H(email)%>" required>
    </div>

    <div class="field">
      <label for="cumple">Fecha de nacimiento</label>
      <input class="input" type="date" id="cumple" name="cumple" value="<%=H(cumple)%>">
    </div>

    <div class="field">
      <label for="foto">Cambiar foto de perfil</label>
      <input class="input" type="file" id="foto" name="foto" accept="image/*" data-preview="imgPrev">
      <span class="hint">JPG, PNG, GIF o WEBP hasta 5 MB.</span>
    </div>
  </div>

  <input type="hidden" name="imagen" value="<%=H(foto)%>">

  <h3 style="margin:28px 0 6px;font-size:16px">Cambiar contrasena</h3>
  <p class="muted" style="margin:0 0 16px;font-size:13px">Deja estos campos vacios si no deseas cambiar tu contrasena.</p>

  <div class="form-grid">
    <div class="field">
      <label for="clave_actual">Contrasena actual</label>
      <input class="input" type="password" id="clave_actual" name="clave_actual" maxlength="50" autocomplete="off">
    </div>
    <div class="field"></div>
    <div class="field">
      <label for="clave">Nueva contrasena</label>
      <input class="input" type="password" id="clave" name="clave" maxlength="50" placeholder="Minimo 6 caracteres" autocomplete="off">
    </div>
    <div class="field">
      <label for="clave2">Repetir nueva contrasena</label>
      <input class="input" type="password" id="clave2" name="clave2" maxlength="50" autocomplete="off">
    </div>
  </div>

  <div class="form-actions">
    <button class="btn btn-primary" type="submit"><%=Icon("check")%>Guardar cambios</button>
    <a class="btn btn-ghost" href="home.asp?f=1"><%=Icon("back")%>Volver al inicio</a>
    <span class="spacer"></span>
    <a class="btn btn-danger" href="<%=Url("logout.asp")%>" target="_top"><%=Icon("logout")%>Cerrar sesion</a>
  </div>
</form>
<%
RenderFrameBottom
CloseDb
%>

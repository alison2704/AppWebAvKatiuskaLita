<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  user-form.asp  -  Alta y edicion de usuarios  (solo ADMIN)
' =====================================================================
RequireAdmin
EnsureFrame

Dim id, esNuevo, rs, errores, usuario, email, cumple, tipo, foto, clave, clave2, subida, cambiarClave

id      = ToInt(Request.QueryString("id"))
If id = 0 Then id = ToInt(FormVal("id"))
esNuevo = (id = 0)

usuario = ""
email   = ""
cumple  = ""
tipo    = ROLE_USER
foto    = "~/" & IMG_USER_DEF

If Not esNuevo Then
  Set rs = DbRs("SELECT * FROM TBL_USER WHERE ID_USER = " & id)
  If rs.EOF Then
    rs.Close
    FlashRedirect "El usuario indicado no existe.", "error", "users.asp"
  End If
  usuario = F(rs, "USERNAME")
  email   = F(rs, "EMAIL")
  cumple  = FormatDateInput(F(rs, "BIRTHDAY"))
  tipo    = ToInt(rs("USER_TYPE"))
  foto    = F(rs, "USER_PHOTO")
  If Len(foto) = 0 Then foto = "~/" & IMG_USER_DEF
  rs.Close
  Set rs = Nothing
End If

errores = ""

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then

  usuario = Trim(FormVal("usuario"))
  email   = Trim(FormVal("email"))
  cumple  = Trim(FormVal("cumple"))
  tipo    = ToInt(FormVal("tipo"))
  foto    = Trim(FormVal("imagen"))
  clave   = FormVal("clave")
  clave2  = FormVal("clave2")

  If tipo <> ROLE_ADMIN Then tipo = ROLE_USER

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

  If esNuevo Then
    If Len(clave) < 6 Then
      errores = errores & "<li>La contrasena debe tener al menos 6 caracteres.</li>"
    End If
    If clave <> clave2 Then
      errores = errores & "<li>Las contrasenas no coinciden.</li>"
    End If
  Else
    If Len(clave) > 0 Then
      If Len(clave) < 6 Then
        errores = errores & "<li>La nueva contrasena debe tener al menos 6 caracteres.</li>"
      End If
      If clave <> clave2 Then
        errores = errores & "<li>Las contrasenas no coinciden.</li>"
      End If
    End If
  End If

  If Len(cumple) > 0 Then
    If Not IsDate(cumple) Then
      errores = errores & "<li>La fecha de nacimiento no es valida.</li>"
    ElseIf CDate(cumple) > Date() Then
      errores = errores & "<li>La fecha de nacimiento no puede ser futura.</li>"
    End If
  End If

  ' ---- unicidad -----------------------------------------------------
  If Len(errores) = 0 Then
    If DbExists("SELECT 1 FROM TBL_USER WHERE USERNAME = " & Q(usuario) & IIfS(Not esNuevo, " AND ID_USER <> " & id, "")) Then
      errores = errores & "<li>El nombre de usuario ya esta en uso.</li>"
    End If
    If DbExists("SELECT 1 FROM TBL_USER WHERE EMAIL = " & Q(email) & IIfS(Not esNuevo, " AND ID_USER <> " & id, "")) Then
      errores = errores & "<li>El correo ya esta registrado.</li>"
    End If
  End If

  ' ---- no degradar al ultimo administrador --------------------------
  If Len(errores) = 0 And Not esNuevo Then
    If tipo <> ROLE_ADMIN Then
      If ToInt(DbScalar("SELECT USER_TYPE FROM TBL_USER WHERE ID_USER = " & id, 0)) = ROLE_ADMIN Then
        If DbCount("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = " & ROLE_ADMIN) <= 1 Then
          errores = errores & "<li>Debe existir al menos un administrador en el sistema.</li>"
        End If
      End If
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

  ' ---- guardar ------------------------------------------------------
  If Len(errores) = 0 Then
    If esNuevo Then
      DbExec "INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) VALUES (" & _
             Q(usuario) & ", " & Q(SHA1(clave)) & ", " & Q(email) & ", " & _
             DQ(cumple) & ", " & Q(foto) & ", " & N(tipo) & ")"
      id = LastId()
      FlashRedirect "Usuario creado correctamente.", "ok", "users.asp"
    Else
      Dim sql
      sql = "UPDATE TBL_USER SET USERNAME = " & Q(usuario) & _
            ", EMAIL = " & Q(email) & _
            ", BIRTHDAY = " & DQ(cumple) & _
            ", USER_PHOTO = " & Q(foto) & _
            ", USER_TYPE = " & N(tipo)
      If Len(clave) > 0 Then sql = sql & ", PASSWORD = " & Q(SHA1(clave))
      sql = sql & " WHERE ID_USER = " & id
      DbExec sql

      ' Si el administrador edita su propia cuenta se refresca la sesion
      If id = UserId() Then
        Session("uname")  = usuario
        Session("uemail") = email
        Session("utype")  = tipo
        Session("uphoto") = foto
      End If
      FlashRedirect "Usuario actualizado correctamente.", "ok", "users.asp"
    End If
  End If
End If

RenderFrameTop IIfS(esNuevo, "Nuevo usuario", "Editar usuario"), "users", "Datos de la cuenta, rol y contrasena."
%>

<% If Len(errores) > 0 Then %>
  <div class="alert"><strong>Revisa lo siguiente:</strong><ul><%=errores%></ul></div>
<% End If %>

<form class="form-card" method="post" action="<%=FUrl("user-form.asp")%>" enctype="multipart/form-data">
  <input type="hidden" name="id" value="<%=id%>">

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
      <label for="clave">Contrasena <% If esNuevo Then %><span class="req">*</span><% End If %></label>
      <input class="input" type="password" id="clave" name="clave" maxlength="50"
             placeholder="<%=IIfS(esNuevo, "Minimo 6 caracteres", "Dejar vacio para no cambiarla")%>"<% If esNuevo Then %> required<% End If %>>
      <span class="hint">Se almacena cifrada con SHA-1.</span>
    </div>

    <div class="field">
      <label for="clave2">Repetir contrasena</label>
      <input class="input" type="password" id="clave2" name="clave2" maxlength="50" placeholder="Repite la contrasena">
    </div>

    <div class="field">
      <label for="cumple">Fecha de nacimiento</label>
      <input class="input" type="date" id="cumple" name="cumple" value="<%=H(cumple)%>">
    </div>

    <div class="field">
      <label for="tipo">Rol</label>
      <select class="select" id="tipo" name="tipo">
        <option value="<%=ROLE_USER%>"<% If tipo = ROLE_USER Then %> selected<% End If %>>Usuario - reproduce y administra sus playlists</option>
        <option value="<%=ROLE_ADMIN%>"<% If tipo = ROLE_ADMIN Then %> selected<% End If %>>Administrador - acceso total al CRUD</option>
      </select>
    </div>

    <div class="field span-2">
      <label for="foto">Foto de perfil</label>
      <input class="input" type="file" id="foto" name="foto" accept="image/*" data-preview="imgPrev">
      <span class="hint">JPG, PNG, GIF o WEBP hasta 5 MB.</span>
    </div>

    <div class="field span-2">
      <label>Foto actual</label>
      <div class="row">
        <img class="preview-thumb round" id="imgPrev" src="<%=H(ImgUser(foto))%>" alt="Vista previa">
        <input type="hidden" name="imagen" value="<%=H(foto)%>">
        <span class="muted"><%=H(foto)%></span>
      </div>
    </div>
  </div>

  <div class="form-actions">
    <button class="btn btn-primary" type="submit"><%=Icon("check")%>Guardar usuario</button>
    <a class="btn btn-ghost" href="users.asp?f=1"><%=Icon("back")%>Cancelar</a>
<% If Not esNuevo Then %>
    <span class="spacer"></span>
    <span class="muted">ID <%=id%></span>
<% End If %>
  </div>
</form>
<%
RenderFrameBottom
CloseDb
%>

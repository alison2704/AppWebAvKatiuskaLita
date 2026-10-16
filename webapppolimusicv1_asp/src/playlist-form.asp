<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  playlist-form.asp  -  Crear / editar / eliminar una playlist
'  El usuario normal solo puede administrar SUS playlists.
'  El administrador puede administrar cualquiera.
' =====================================================================
RequireLogin
EnsureFrame

Dim id, esNuevo, rs, errores, titulo, tipo, img, subida, accion, duenio

id      = ToInt(Request.QueryString("id"))
If id = 0 Then id = ToInt(FormVal("id"))
esNuevo = (id = 0)

titulo = ""
tipo   = PL_PUBLIC
img    = "~/" & IMG_PLAYLIST_DEF
duenio = UserId()

If Not esNuevo Then
  If Not DbExists("SELECT 1 FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & id) Then
    FlashRedirect "La playlist indicada no existe.", "error", "playlists.asp"
  End If
  If Not CanManagePlaylist(id) Then
    FlashRedirect "Solo puedes administrar tus propias playlists.", "error", "playlists.asp"
  End If
  Set rs = DbRs("SELECT * FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & id)
  titulo = F(rs, "TITLE")
  tipo   = ToInt(rs("TYPE"))
  img    = F(rs, "PHOTO")
  duenio = ToInt(rs("ID_USER"))
  If Len(img) = 0 Then img = "~/" & IMG_PLAYLIST_DEF
  rs.Close
  Set rs = Nothing
End If

errores = ""

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then

  accion = FormVal("accion")

  ' ------------------------------ eliminar --------------------------
  If accion = "eliminar" Then
    If Not CanManagePlaylist(id) Then
      FlashRedirect "No tienes permisos sobre esa playlist.", "error", "playlists.asp"
    End If
    titulo = CStr(DbScalar("SELECT TITLE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & id, ""))
    DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = " & id
    DbExec "DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & id
    FlashRedirect "Playlist """ & titulo & """ eliminada correctamente.", "ok", "playlists.asp"
  End If

  ' ------------------------------ guardar ---------------------------
  titulo = Trim(FormVal("titulo"))
  tipo   = ToInt(FormVal("tipo"))
  img    = Trim(FormVal("imagen"))

  If tipo <> PL_PRIVATE Then tipo = PL_PUBLIC

  If Len(titulo) = 0 Then
    errores = errores & "<li>El titulo de la playlist es obligatorio.</li>"
  ElseIf Len(titulo) > 50 Then
    errores = errores & "<li>El titulo no puede superar los 50 caracteres.</li>"
  End If

  subida = ""
  If HasUpload("foto") And UploadSize("foto") > 0 Then
    If UploadSize("foto") > UPLOAD_MAX_IMAGE Then
      errores = errores & "<li>La imagen supera el limite de 5 MB.</li>"
    Else
      subida = SaveUpload("foto", DIR_PLAYLIST, EXT_IMAGE, UPLOAD_MAX_IMAGE, titulo)
      If Len(subida) = 0 Then
        errores = errores & "<li>El formato de la imagen no es valido (JPG, PNG, GIF o WEBP).</li>"
      End If
    End If
  End If

  If Len(subida) > 0 Then
    img = subida
  ElseIf Len(img) = 0 Then
    img = "~/" & IMG_PLAYLIST_DEF
  End If

  If Len(errores) = 0 Then
    If esNuevo Then
      DbExec "INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) VALUES (" & _
             N(UserId()) & ", " & Q(titulo) & ", " & DQ(FormatDateInput(Date())) & ", " & N(tipo) & ", " & Q(img) & ")"
      id = LastId()
      FlashRedirect "Playlist creada correctamente. Ya puedes agregarle canciones.", "ok", "playlist-detail.asp?id=" & id
    Else
      DbExec "UPDATE TBL_PLAYLIST SET TITLE = " & Q(titulo) & _
             ", TYPE = " & N(tipo) & _
             ", PHOTO = " & Q(img) & _
             " WHERE ID_PLAYLIST = " & id
      FlashRedirect "Playlist guardada correctamente.", "ok", "playlist-detail.asp?id=" & id
    End If
  End If
End If

RenderFrameTop IIfS(esNuevo, "Nueva playlist", "Editar playlist"), "playlists", "Define el nombre, la visibilidad y la portada de tu lista."
%>

<% If Len(errores) > 0 Then %>
  <div class="alert"><strong>Revisa lo siguiente:</strong><ul><%=errores%></ul></div>
<% End If %>

<form class="form-card" method="post" action="<%=FUrl("playlist-form.asp")%>" enctype="multipart/form-data">
  <input type="hidden" name="id" value="<%=id%>">
  <input type="hidden" name="accion" value="guardar">

  <div class="form-grid">
    <div class="field span-2">
      <label for="titulo">Titulo <span class="req">*</span></label>
      <input class="input" type="text" id="titulo" name="titulo" maxlength="50" value="<%=H(titulo)%>"
             placeholder="Mi playlist favorita" required>
    </div>

    <div class="field">
      <label for="tipo">Visibilidad</label>
      <select class="select" id="tipo" name="tipo">
        <option value="<%=PL_PUBLIC%>"<% If tipo = PL_PUBLIC Then %> selected<% End If %>>Publica - todos pueden verla</option>
        <option value="<%=PL_PRIVATE%>"<% If tipo = PL_PRIVATE Then %> selected<% End If %>>Privada - solo tu</option>
      </select>
    </div>

    <div class="field">
      <label for="foto">Portada</label>
      <input class="input" type="file" id="foto" name="foto" accept="image/*" data-preview="imgPrev">
      <span class="hint">JPG, PNG, GIF o WEBP hasta 5 MB.</span>
    </div>

    <div class="field span-2">
      <label>Portada actual</label>
      <div class="row">
        <img class="preview-thumb" id="imgPrev" src="<%=H(ImgPlaylist(img))%>" alt="Vista previa">
        <input type="hidden" name="imagen" value="<%=H(img)%>">
        <span class="muted"><%=H(img)%></span>
      </div>
    </div>
  </div>

  <div class="form-actions">
    <button class="btn btn-primary" type="submit"><%=Icon("check")%>Guardar playlist</button>
    <a class="btn btn-ghost" href="playlists.asp?f=1"><%=Icon("back")%>Cancelar</a>
<% If Not esNuevo Then %>
    <span class="spacer"></span>
    <span class="muted">ID <%=id%></span>
<% End If %>
  </div>
</form>

<% If Not esNuevo Then %>
<form class="form-card" method="post" action="<%=FUrl("playlist-form.asp")%>" style="margin-top:18px;border-color:rgba(217,83,79,.35)"
      data-confirm="Eliminar la playlist &quot;<%=H(titulo)%>&quot;? Se quitaran todas sus canciones.">
  <input type="hidden" name="id" value="<%=id%>">
  <input type="hidden" name="accion" value="eliminar">
  <div class="row">
    <div>
      <strong>Zona de riesgo</strong>
      <p class="muted mb-0">Se eliminara la playlist junto con su lista de canciones. Las canciones no se borran del catalogo.</p>
    </div>
    <span class="grow"></span>
    <button class="btn btn-danger" type="submit"><%=Icon("trash")%>Eliminar playlist</button>
  </div>
</form>
<% End If %>
<%
RenderFrameBottom
CloseDb
%>

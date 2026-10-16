<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  album-form.asp  -  Alta y edicion de albumes  (solo ADMIN)
' =====================================================================
RequireAdmin
EnsureFrame

Dim id, esNuevo, rs, errores, titulo, anio, img, subida

id      = ToInt(Request.QueryString("id"))
If id = 0 Then id = ToInt(FormVal("id"))
esNuevo = (id = 0)

titulo = ""
anio   = Year(Date())
img    = "~/" & IMG_ALBUM_DEF

If Not esNuevo Then
  Set rs = DbRs("SELECT * FROM TBL_ALBUM WHERE ID_ALBUM = " & id)
  If rs.EOF Then
    rs.Close
    FlashRedirect "El album indicado no existe.", "error", "albums.asp"
  End If
  titulo = F(rs, "TITLE_ALBUM")
  anio   = ToInt(rs("RELEASE_YEAR"))
  img    = F(rs, "ALBUM_IMAGE_PATH")
  If Len(img) = 0 Then img = "~/" & IMG_ALBUM_DEF
  rs.Close
  Set rs = Nothing
End If

errores = ""

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then

  titulo = Trim(FormVal("titulo"))
  anio   = ToInt(FormVal("anio"))
  img    = Trim(FormVal("imagen"))

  If Len(titulo) = 0 Then
    errores = errores & "<li>El titulo del album es obligatorio.</li>"
  ElseIf Len(titulo) > 50 Then
    errores = errores & "<li>El titulo no puede superar los 50 caracteres.</li>"
  End If

  If anio < 1900 Or anio > 2100 Then
    errores = errores & "<li>El anio de lanzamiento debe estar entre 1900 y 2100.</li>"
  End If

  subida = ""
  If HasUpload("foto") And UploadSize("foto") > 0 Then
    If UploadSize("foto") > UPLOAD_MAX_IMAGE Then
      errores = errores & "<li>La imagen supera el limite de 5 MB.</li>"
    Else
      subida = SaveUpload("foto", DIR_ALBUM, EXT_IMAGE, UPLOAD_MAX_IMAGE, titulo)
      If Len(subida) = 0 Then
        errores = errores & "<li>El formato de la imagen no es valido (JPG, PNG, GIF o WEBP).</li>"
      End If
    End If
  End If

  If Len(subida) > 0 Then
    img = subida
  ElseIf Len(img) = 0 Then
    img = "~/" & IMG_ALBUM_DEF
  End If

  If Len(errores) = 0 Then
    If esNuevo Then
      DbExec "INSERT INTO TBL_ALBUM (TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH) VALUES (" & _
             Q(titulo) & ", " & N(anio) & ", " & Q(img) & ")"
      id = LastId()
      FlashRedirect "Album creado. Ahora puedes agregarle canciones.", "ok", "album-detail.asp?id=" & id
    Else
      DbExec "UPDATE TBL_ALBUM SET TITLE_ALBUM = " & Q(titulo) & _
             ", RELEASE_YEAR = " & N(anio) & _
             ", ALBUM_IMAGE_PATH = " & Q(img) & _
             " WHERE ID_ALBUM = " & id
      FlashRedirect "Album guardado correctamente.", "ok", "album-detail.asp?id=" & id
    End If
  End If
End If

RenderFrameTop IIfS(esNuevo, "Nuevo album", "Editar album"), "albums", "Datos del album y su portada."
%>

<% If Len(errores) > 0 Then %>
  <div class="alert"><strong>Revisa lo siguiente:</strong><ul><%=errores%></ul></div>
<% End If %>

<form class="form-card" method="post" action="<%=FUrl("album-form.asp")%>" enctype="multipart/form-data">
  <input type="hidden" name="id" value="<%=id%>">

  <div class="form-grid">
    <div class="field span-2">
      <label for="titulo">Titulo del album <span class="req">*</span></label>
      <input class="input" type="text" id="titulo" name="titulo" maxlength="50" value="<%=H(titulo)%>" required>
    </div>

    <div class="field">
      <label for="anio">Anio de lanzamiento</label>
      <input class="input" type="number" id="anio" name="anio" min="1900" max="2100" value="<%=anio%>">
    </div>

    <div class="field">
      <label for="foto">Portada</label>
      <input class="input" type="file" id="foto" name="foto" accept="image/*" data-preview="imgPrev">
      <span class="hint">JPG, PNG, GIF o WEBP hasta 5 MB.</span>
    </div>

    <div class="field span-2">
      <label>Portada actual</label>
      <div class="row">
        <img class="preview-thumb" id="imgPrev" src="<%=H(ImgAlbum(img))%>" alt="Vista previa">
        <input type="hidden" name="imagen" value="<%=H(img)%>">
        <span class="muted"><%=H(img)%></span>
      </div>
    </div>
  </div>

  <div class="form-actions">
    <button class="btn btn-primary" type="submit"><%=Icon("check")%>Guardar album</button>
    <a class="btn btn-ghost" href="albums.asp?f=1"><%=Icon("back")%>Cancelar</a>
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

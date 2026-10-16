<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  artist-form.asp  -  Alta y edicion de artistas  (solo ADMIN)
' =====================================================================
RequireAdmin
EnsureFrame

Dim id, esNuevo, rs, errores, nombre, apellido, img, subida

id      = ToInt(Request.QueryString("id"))
If id = 0 Then id = ToInt(FormVal("id"))
esNuevo = (id = 0)

nombre   = ""
apellido = ""
img      = "~/" & IMG_ARTIST_DEF

If Not esNuevo Then
  Set rs = DbRs("SELECT * FROM TBL_ARTIST WHERE ID_ARTIST = " & id)
  If rs.EOF Then
    rs.Close
    FlashRedirect "El artista indicado no existe.", "error", "artists.asp"
  End If
  nombre   = F(rs, "ARTIST_NAME")
  apellido = F(rs, "ARTIST_LASTNAME")
  img      = F(rs, "ARTIST_IMAGE")
  If Len(img) = 0 Then img = "~/" & IMG_ARTIST_DEF
  rs.Close
  Set rs = Nothing
End If

errores = ""

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then

  nombre   = Trim(FormVal("nombre"))
  apellido = Trim(FormVal("apellido"))
  img      = Trim(FormVal("imagen"))

  If Len(nombre) = 0 Then
    errores = errores & "<li>El nombre del artista es obligatorio.</li>"
  ElseIf Len(nombre) > 100 Then
    errores = errores & "<li>El nombre no puede superar los 100 caracteres.</li>"
  End If
  If Len(apellido) > 100 Then
    errores = errores & "<li>El apellido no puede superar los 100 caracteres.</li>"
  End If

  subida = ""
  If HasUpload("foto") And UploadSize("foto") > 0 Then
    If UploadSize("foto") > UPLOAD_MAX_IMAGE Then
      errores = errores & "<li>La imagen supera el limite de 5 MB.</li>"
    Else
      subida = SaveUpload("foto", DIR_ARTIST, EXT_IMAGE, UPLOAD_MAX_IMAGE, nombre)
      If Len(subida) = 0 Then
        errores = errores & "<li>El formato de la imagen no es valido (JPG, PNG, GIF o WEBP).</li>"
      End If
    End If
  End If

  If Len(subida) > 0 Then
    img = subida
  ElseIf Len(img) = 0 Then
    img = "~/" & IMG_ARTIST_DEF
  End If

  If Len(errores) = 0 Then
    If esNuevo Then
      DbExec "INSERT INTO TBL_ARTIST (ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE) VALUES (" & _
             Q(nombre) & ", " & Q(apellido) & ", " & Q(img) & ")"
    Else
      DbExec "UPDATE TBL_ARTIST SET ARTIST_NAME = " & Q(nombre) & _
             ", ARTIST_LASTNAME = " & Q(apellido) & _
             ", ARTIST_IMAGE = " & Q(img) & _
             " WHERE ID_ARTIST = " & id
    End If
    FlashRedirect "Artista guardado correctamente.", "ok", "artists.asp"
  End If
End If

RenderFrameTop IIfS(esNuevo, "Nuevo artista", "Editar artista"), "artists", "Datos del artista y su fotografia."
%>

<% If Len(errores) > 0 Then %>
  <div class="alert"><strong>Revisa lo siguiente:</strong><ul><%=errores%></ul></div>
<% End If %>

<form class="form-card" method="post" action="<%=FUrl("artist-form.asp")%>" enctype="multipart/form-data">
  <input type="hidden" name="id" value="<%=id%>">

  <div class="form-grid">
    <div class="field">
      <label for="nombre">Nombre <span class="req">*</span></label>
      <input class="input" type="text" id="nombre" name="nombre" maxlength="100" value="<%=H(nombre)%>" required>
    </div>
    <div class="field">
      <label for="apellido">Apellido</label>
      <input class="input" type="text" id="apellido" name="apellido" maxlength="100" value="<%=H(apellido)%>">
    </div>

    <div class="field span-2">
      <label for="foto">Fotografia</label>
      <input class="input" type="file" id="foto" name="foto" accept="image/*" data-preview="imgPrev">
      <span class="hint">JPG, PNG, GIF o WEBP hasta 5 MB. Si no subes nada se conserva la imagen actual.</span>
    </div>

    <div class="field span-2">
      <label>Imagen actual</label>
      <div class="row">
        <img class="preview-thumb round" id="imgPrev" src="<%=H(ImgArtist(img))%>" alt="Vista previa">
        <input type="hidden" name="imagen" value="<%=H(img)%>">
        <span class="muted"><%=H(img)%></span>
      </div>
    </div>
  </div>

  <div class="form-actions">
    <button class="btn btn-primary" type="submit"><%=Icon("check")%>Guardar artista</button>
    <a class="btn btn-ghost" href="artists.asp?f=1"><%=Icon("back")%>Cancelar</a>
<% If Not esNuevo Then %>
    <span class="spacer"></span>
    <span class="muted">ID <%=id%></span>
<% End If %>
  </div>
</form>

<% If Not esNuevo Then %>
<form class="form-card" method="post" action="<%=FUrl("artists.asp")%>" style="margin-top:18px;border-color:rgba(217,83,79,.35)"
      data-confirm="Eliminar el artista &quot;<%=H(nombre)%>&quot;? Se perderan sus asociaciones con canciones.">
  <div class="row">
    <div>
      <strong>Zona de riesgo</strong>
      <p class="muted mb-0">Al eliminar el artista tambien se quitan sus relaciones con las canciones.</p>
    </div>
    <span class="grow"></span>
    <input type="hidden" name="accion" value="eliminar">
    <input type="hidden" name="id" value="<%=id%>">
    <button class="btn btn-danger" type="submit"><%=Icon("trash")%>Eliminar artista</button>
  </div>
</form>
<% End If %>
<%
RenderFrameBottom
CloseDb
%>

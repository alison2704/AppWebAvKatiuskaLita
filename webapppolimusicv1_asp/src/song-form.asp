<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  song-form.asp  -  Alta y edicion de canciones  (solo ADMIN)
' =====================================================================
RequireAdmin
EnsureFrame

Dim id, esNuevo, rs, errores, nombre, ruta, plays, rutaSubida, elegido
Dim rsArtistas, artistasSel, i, j, existe

id      = ToInt(Request.QueryString("id"))
If id = 0 Then id = ToInt(FormVal("id"))
esNuevo = (id = 0)

nombre  = ""
ruta    = ""
plays   = 0

' Datos actuales (edicion)
If Not esNuevo Then
  Set rs = DbRs("SELECT * FROM TBL_SONG WHERE ID_SONG = " & id)
  If rs.EOF Then
    rs.Close
    FlashRedirect "La cancion indicada no existe.", "error", "songs.asp"
  End If
  nombre = F(rs, "SONG_NAME")
  ruta   = F(rs, "SONG_PATH")
  plays  = ToInt(rs("PLAYS"))
  rs.Close
  Set rs = Nothing
End If

' Lista de artistas para las casillas
Set rsArtistas = DbRs(ArtistSelectSql("", "ar.ARTIST_NAME", 0))
Dim totalArtistas
totalArtistas = 0
Do While Not rsArtistas.EOF
  totalArtistas = totalArtistas + 1
  rsArtistas.MoveNext
Loop
rsArtistas.MoveFirst

errores = ""

' ------------------------------- POST ---------------------------------
If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then

  nombre = Trim(FormVal("nombre"))
  ruta   = Trim(FormVal("ruta"))
  plays  = ToInt(FormVal("plays"))
  If plays < 0 Then plays = 0
  elegido = Trim(FormVal("archivo_existente"))

  If Len(nombre) = 0 Then
    errores = errores & "<li>El nombre de la cancion es obligatorio.</li>"
  ElseIf Len(nombre) > 50 Then
    errores = errores & "<li>El nombre no puede superar los 50 caracteres.</li>"
  End If

  ' ---- archivo de audio -------------------------------------------
  rutaSubida = ""
  If HasUpload("archivo") And UploadSize("archivo") > 0 Then
    If UploadSize("archivo") > UPLOAD_MAX_AUDIO Then
      errores = errores & "<li>El archivo de audio supera el limite de 30 MB.</li>"
    Else
      rutaSubida = SaveUpload("archivo", DIR_SONG, EXT_AUDIO, UPLOAD_MAX_AUDIO, nombre)
      If Len(rutaSubida) = 0 Then
        errores = errores & "<li>El formato del audio no es valido (mp3, wav, ogg, m4a o aac).</li>"
      End If
    End If
  End If

  If Len(rutaSubida) > 0 Then
    ruta = rutaSubida
  ElseIf Len(elegido) > 0 Then
    ruta = "~/" & DIR_SONG & "/" & StripPath(elegido)
  ElseIf Len(ruta) = 0 And esNuevo Then
    errores = errores & "<li>Sube un archivo de audio o indica la ruta del archivo.</li>"
  End If

  ' ---- guardar ----------------------------------------------------
  If Len(errores) = 0 Then
    If esNuevo Then
      DbExec "INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (" & _
             Q(nombre) & ", " & Q(ruta) & ", " & N(plays) & ")"
      id = LastId()
    Else
      DbExec "UPDATE TBL_SONG SET SONG_NAME = " & Q(nombre) & _
             ", SONG_PATH = " & Q(ruta) & ", PLAYS = " & N(plays) & _
             " WHERE ID_SONG = " & id
    End If

    ' ---- artistas interpretes (TBL_PLAYER) -----------------------
    DbExec "DELETE FROM TBL_PLAYER WHERE ID_SONG = " & id
    rsArtistas.MoveFirst
    Do While Not rsArtistas.EOF
      If Len(FormVal("artista_" & ToInt(rsArtistas("ID_ARTIST")))) > 0 Then
        DbExec "INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) VALUES (" & id & ", " & ToInt(rsArtistas("ID_ARTIST")) & ")"
      End If
      rsArtistas.MoveNext
    Loop

    FlashRedirect "Cancion guardada correctamente.", "ok", "songs.asp"
  End If
End If

' Artistas marcados actualmente
Dim marcados
marcados = ","
If Not esNuevo And Len(errores) = 0 Then
  Dim rsSel
  Set rsSel = DbRs("SELECT ID_ARTIST FROM TBL_PLAYER WHERE ID_SONG = " & id)
  Do While Not rsSel.EOF
    marcados = marcados & ToInt(rsSel("ID_ARTIST")) & ","
    rsSel.MoveNext
  Loop
  rsSel.Close
  Set rsSel = Nothing
ElseIf Len(errores) > 0 Then
  rsArtistas.MoveFirst
  Do While Not rsArtistas.EOF
    If Len(FormVal("artista_" & ToInt(rsArtistas("ID_ARTIST")))) > 0 Then
      marcados = marcados & ToInt(rsArtistas("ID_ARTIST")) & ","
    End If
    rsArtistas.MoveNext
  Loop
End If

RenderFrameTop IIfS(esNuevo, "Nueva cancion", "Editar cancion"), "songs", "Completa los datos de la cancion y su archivo de audio."
%>

<% If Len(errores) > 0 Then %>
  <div class="alert"><strong>Revisa lo siguiente:</strong><ul><%=errores%></ul></div>
<% End If %>

<form class="form-card" method="post" action="<%=FUrl("song-form.asp")%>" enctype="multipart/form-data">
  <input type="hidden" name="id" value="<%=id%>">

  <div class="form-grid">
    <div class="field span-2">
      <label for="nombre">Nombre de la cancion <span class="req">*</span></label>
      <input class="input" type="text" id="nombre" name="nombre" maxlength="50" value="<%=H(nombre)%>" required>
    </div>

    <div class="field">
      <label for="archivo">Archivo de audio</label>
      <input class="input" type="file" id="archivo" name="archivo" accept="audio/*">
      <span class="hint">MP3, WAV, OGG, M4A o AAC. Maximo 30 MB.</span>
    </div>

    <div class="field">
      <label for="archivo_existente">O elige un archivo del servidor</label>
      <select class="select" id="archivo_existente" name="archivo_existente">
        <option value="">-- Ninguno --</option>
        <%
        Dim fso, carpeta, arch, nombreArch, sel
        On Error Resume Next
        Set fso = Server.CreateObject("Scripting.FileSystemObject")
        carpeta = Server.MapPath(Url(DIR_SONG))
        If fso.FolderExists(carpeta) Then
          For Each arch In fso.GetFolder(carpeta).Files
            nombreArch = arch.Name
            If InStr(1, "," & EXT_AUDIO & ",", "," & LCase(FileExt(nombreArch)) & ",", 1) > 0 Then
              sel = ""
              If InStr(ruta, nombreArch) > 0 Then sel = " selected"
        %>
        <option value="<%=H(nombreArch)%>"<%=sel%>><%=H(nombreArch)%></option>
        <%
            End If
          Next
        End If
        Set fso = Nothing
        On Error GoTo 0
        %>
      </select>
    </div>

    <div class="field span-2">
      <label for="ruta">Ruta guardada</label>
      <input class="input" type="text" id="ruta" name="ruta" maxlength="255" value="<%=H(ruta)%>" placeholder="~/SongFiles/mi-cancion.mp3">
      <span class="hint">Si subes un archivo o eliges uno de la lista, la ruta se actualiza automaticamente.</span>
    </div>

    <div class="field">
      <label for="plays">Reproducciones</label>
      <input class="input" type="number" id="plays" name="plays" min="0" value="<%=plays%>">
    </div>
  </div>

  <div class="field" style="margin-top:22px">
    <label>Artistas interpretes</label>
    <span class="hint">Marca uno o varios artistas para esta cancion.</span>
    <div class="card-grid" style="grid-template-columns:repeat(auto-fill,minmax(210px,1fr));margin-top:10px">
<%
  Do While Not rsArtistas.EOF
    Dim aid, anombre, checkedAttr
    aid = ToInt(rsArtistas("ID_ARTIST"))
    anombre = ArtistNameOf(rsArtistas, "ARTIST_NAME", "ARTIST_LASTNAME")
    If InStr(marcados, "," & aid & ",") > 0 Then checkedAttr = " checked" Else checkedAttr = ""
%>
      <label class="card" style="flex-direction:row;align-items:center;gap:11px;padding:10px;cursor:pointer">
        <input type="checkbox" name="artista_<%=aid%>" value="1"<%=checkedAttr%>>
        <img class="lr-art" src="<%=H(ImgArtist(F(rsArtistas, "ARTIST_IMAGE")))%>" alt="">
        <span style="min-width:0">
          <span class="card-title" style="display:block"><%=H(anombre)%></span>
          <span class="card-sub"><%=ToInt(rsArtistas("SONGS"))%> canciones</span>
        </span>
      </label>
<%
    rsArtistas.MoveNext
  Loop
  If totalArtistas = 0 Then
%>
      <p class="muted">Todavia no hay artistas registrados.
        <a href="artist-form.asp?f=1">Crear un artista</a></p>
<%
  End If
%>
    </div>
  </div>

  <div class="form-actions">
    <button class="btn btn-primary" type="submit"><%=Icon("check")%>Guardar cancion</button>
    <a class="btn btn-ghost" href="songs.asp?f=1"><%=Icon("back")%>Cancelar</a>
<% If Not esNuevo Then %>
    <span class="spacer"></span>
    <span class="muted">ID <%=id%></span>
<% End If %>
  </div>
</form>
<%
rsArtistas.Close
Set rsArtistas = Nothing

RenderFrameBottom
CloseDb
%>

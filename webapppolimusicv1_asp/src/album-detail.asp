<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  album-detail.asp  -  Detalle del album y gestion de su tracklist
' =====================================================================
RequireLogin
EnsureFrame

Dim id, rs, titulo, anio, img, nTracks, accion, idSong, artista

id = ToInt(Request.QueryString("id"))
If id = 0 Then id = ToInt(FormVal("id_album"))
If id <= 0 Then FlashRedirect "Album no valido.", "error", "albums.asp"

' ------------------------------- POST ---------------------------------
If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
  accion = FormVal("accion")
  idSong = ToInt(FormVal("id_song"))

  If Not IsAdmin() Then
    FlashRedirect "Solo un administrador puede modificar el tracklist.", "error", "album-detail.asp?id=" & id
  End If

  If accion = "quitar" And idSong > 0 Then
    DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = " & id & " AND ID_SONG = " & idSong
    FlashRedirect "Cancion quitada del album.", "ok", "album-detail.asp?id=" & id
  ElseIf accion = "agregar" And idSong > 0 Then
    If Not DbExists("SELECT 1 FROM TBL_TRACKLIST WHERE ID_ALBUM = " & id & " AND ID_SONG = " & idSong) Then
      DbExec "INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) VALUES (" & id & ", " & idSong & ")"
      FlashRedirect "Cancion agregada al album.", "ok", "album-detail.asp?id=" & id
    Else
      FlashRedirect "Esa cancion ya forma parte del album.", "error", "album-detail.asp?id=" & id
    End If
  ElseIf accion = "eliminar" Then
    titulo = CStr(DbScalar("SELECT TITLE_ALBUM FROM TBL_ALBUM WHERE ID_ALBUM = " & id, ""))
    DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = " & id
    DbExec "DELETE FROM TBL_ALBUM WHERE ID_ALBUM = " & id
    FlashRedirect "Album """ & titulo & """ eliminado correctamente.", "ok", "albums.asp"
  Else
    FlashRedirect "Accion no reconocida.", "error", "album-detail.asp?id=" & id
  End If
End If

' ------------------------------- Datos --------------------------------
Set rs = DbRs(AlbumSelectSql("al.ID_ALBUM = " & id, "", 0))
If rs.EOF Then
  rs.Close
  FlashRedirect "El album indicado no existe.", "error", "albums.asp"
End If
titulo  = F(rs, "TITLE_ALBUM")
anio    = ToInt(rs("RELEASE_YEAR"))
img     = ImgAlbum(F(rs, "ALBUM_IMAGE_PATH"))
nTracks = ToInt(rs("TRACKS"))
artista = F(rs, "ARTISTS")
If Len(artista) = 0 Then artista = "Artista desconocido"
rs.Close
Set rs = Nothing

RenderFrameTop titulo, "albums", "Album"
%>

<div class="hero">
  <img class="hero-cover" src="<%=H(img)%>" alt="<%=H(titulo)%>">
  <div class="hero-body">
    <span class="hero-kicker">Album</span>
    <h1 class="hero-title"><%=H(titulo)%></h1>
    <div class="hero-meta">
      <span><%=H(artista)%></span>
      <span>&middot;</span>
      <span><%=IIfS(anio > 0, anio & " &middot; ", "")%><%=nTracks%> canciones</span>
    </div>
    <div class="hero-actions">
      <a class="btn btn-primary" href="albums.asp?f=1"><%=Icon("back")%>Volver a albumes</a>
      <% If IsAdmin() Then %>
        <a class="btn btn-ghost" href="album-form.asp?f=1&amp;id=<%=id%>"><%=Icon("edit")%>Editar album</a>
      <% End If %>
    </div>
  </div>
</div>

<div class="section">
  <div class="section-head">
    <h2>Tracklist</h2>
    <span class="muted"><%=nTracks%> canciones</span>
  </div>

  <% If nTracks > 0 Then %>
    <div class="list">
      <%
      Set rs = DbRs(SongSelectSql("EXISTS (SELECT 1 FROM TBL_TRACKLIST t WHERE t.ID_SONG = s.ID_SONG AND t.ID_ALBUM = " & id & ")", "s.SONG_NAME", 0))
      RenderTrackList rs, IIfS(IsAdmin(), "album", "read"), id
      rs.Close
      Set rs = Nothing
      %>
    </div>
  <% Else %>
    <% RenderEmpty "song", "Album sin canciones", "Todavia no se han agregado canciones a este album.", "", "" %>
  <% End If %>
</div>

<% If IsAdmin() Then %>
<div class="section">
  <div class="section-head"><h2>Agregar cancion al album</h2></div>
  <form class="form-card" method="post" action="<%=FUrl("album-detail.asp")%>" style="max-width:640px">
    <input type="hidden" name="id_album" value="<%=id%>">
    <input type="hidden" name="accion" value="agregar">
    <div class="field">
      <label for="id_song">Cancion disponible</label>
      <select class="select" id="id_song" name="id_song" required>
        <option value="">-- Selecciona una cancion --</option>
        <%
        Dim rsDisp
        Set rsDisp = DbRs(SongSelectSql("NOT EXISTS (SELECT 1 FROM TBL_TRACKLIST t WHERE t.ID_SONG = s.ID_SONG AND t.ID_ALBUM = " & id & ")", "s.SONG_NAME", 0))
        Do While Not rsDisp.EOF
        %>
        <option value="<%=ToInt(rsDisp("ID_SONG"))%>"><%=H(F(rsDisp, "SONG_NAME"))%> &mdash; <%=H(F(rsDisp, "ARTISTS"))%></option>
        <%
          rsDisp.MoveNext
        Loop
        If rsDisp.EOF And rsDisp.BOF Then
        %>
        <option value="">(Todas las canciones ya estan en el album)</option>
        <%
        End If
        rsDisp.Close
        Set rsDisp = Nothing
        %>
      </select>
    </div>
    <div class="form-actions">
      <button class="btn btn-primary" type="submit"><%=Icon("plus")%>Agregar al album</button>
    </div>
  </form>

  <form class="form-card" method="post" action="<%=FUrl("album-detail.asp")%>" style="margin-top:18px;border-color:rgba(217,83,79,.35)"
        data-confirm="Eliminar el album &quot;<%=H(titulo)%>&quot;? Tambien se vaciara su tracklist.">
    <input type="hidden" name="id_album" value="<%=id%>">
    <input type="hidden" name="accion" value="eliminar">
    <div class="row">
      <div>
        <strong>Zona de riesgo</strong>
        <p class="muted mb-0">Eliminar el album no borra las canciones, solo la relacion con ellas.</p>
      </div>
      <span class="grow"></span>
      <button class="btn btn-danger" type="submit"><%=Icon("trash")%>Eliminar album</button>
    </div>
  </form>
</div>
<% End If %>
<%
RenderFrameBottom
CloseDb
%>

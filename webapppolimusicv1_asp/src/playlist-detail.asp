<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  playlist-detail.asp  -  Detalle de la playlist y gestion de canciones
'  Puede administrarla: el duenio de la playlist o un administrador.
' =====================================================================
RequireLogin
EnsureFrame

Dim id, rs, titulo, tipo, img, nSongs, fecha, duenio, puede, accion, idSong

id = ToInt(Request.QueryString("id"))
If id = 0 Then id = ToInt(FormVal("id_playlist"))
If id <= 0 Then FlashRedirect "Playlist no valida.", "error", "playlists.asp"

If Not DbExists("SELECT 1 FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & id) Then
  FlashRedirect "La playlist indicada no existe.", "error", "playlists.asp"
End If

If Not CanViewPlaylist(id) Then
  FlashRedirect "Esta playlist es privada.", "error", "playlists.asp"
End If

puede = CanManagePlaylist(id)

' ------------------------------- POST ---------------------------------
If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
  accion = FormVal("accion")
  idSong = ToInt(FormVal("id_song"))

  If Not puede Then
    FlashRedirect "Solo el duenio de la playlist puede modificarla.", "error", "playlist-detail.asp?id=" & id
  End If

  If accion = "quitar" And idSong > 0 Then
    DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = " & id & " AND ID_SONG = " & idSong
    FlashRedirect "Cancion quitada de la playlist.", "ok", "playlist-detail.asp?id=" & id
  ElseIf accion = "agregar" And idSong > 0 Then
    If Not DbExists("SELECT 1 FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = " & id & " AND ID_SONG = " & idSong) Then
      DbExec "INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) VALUES (" & id & ", " & idSong & ")"
      FlashRedirect "Cancion agregada a la playlist.", "ok", "playlist-detail.asp?id=" & id
    Else
      FlashRedirect "Esa cancion ya esta en la playlist.", "error", "playlist-detail.asp?id=" & id
    End If
  Else
    FlashRedirect "Accion no reconocida.", "error", "playlist-detail.asp?id=" & id
  End If
End If

' ------------------------------- Datos --------------------------------
Set rs = DbRs(PlaylistSelectSql("pl.ID_PLAYLIST = " & id, "", 0))
titulo = F(rs, "TITLE")
tipo   = ToInt(rs("TYPE"))
img    = ImgPlaylist(F(rs, "PHOTO"))
nSongs = ToInt(rs("SONGS"))
fecha  = F(rs, "CREATION_DATE")
duenio = F(rs, "USERNAME")
rs.Close
Set rs = Nothing

RenderFrameTop titulo, "playlists", "Playlist"
%>

<div class="hero">
  <img class="hero-cover" src="<%=H(img)%>" alt="<%=H(titulo)%>">
  <div class="hero-body">
    <span class="hero-kicker">Playlist <%=H(PlaylistTypeLabel(tipo))%></span>
    <h1 class="hero-title"><%=H(titulo)%></h1>
    <div class="hero-meta">
      <span><%=H(duenio)%></span>
      <span>&middot;</span>
      <span><%=nSongs%> canciones</span>
      <span>&middot;</span>
      <span>Creada el <%=H(FormatDate(fecha))%></span>
      <span class="badge <%=IIfS(tipo = PL_PRIVATE, "badge-private", "badge-public")%>">
        <%=Icon(IIfS(tipo = PL_PRIVATE, "lock", "globe"))%><%=H(PlaylistTypeLabel(tipo))%>
      </span>
    </div>
    <div class="hero-actions">
      <% If nSongs > 0 Then %>
        <button type="button" class="btn btn-primary" data-play-all><%=Icon("play")%>Reproducir todo</button>
      <% End If %>
      <a class="btn btn-ghost" href="playlists.asp?f=1"><%=Icon("back")%>Volver</a>
      <% If puede Then %>
        <a class="btn btn-ghost" href="playlist-form.asp?f=1&amp;id=<%=id%>"><%=Icon("edit")%>Editar playlist</a>
      <% End If %>
    </div>
  </div>
</div>

<div class="section">
  <div class="section-head">
    <h2>Canciones</h2>
    <span class="muted"><%=nSongs%> en la lista</span>
  </div>
<%
Set rs = DbRs(SongSelectSql("EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_SONG = s.ID_SONG AND ps.ID_PLAYLIST = " & id & ")", "s.SONG_NAME", 0))
If rs.EOF Then
  RenderEmpty "song", "Playlist vacia", "Agrega canciones del catalogo para empezar a escuchar.", "", ""
Else
%>
  <div class="list">
    <% RenderTrackList rs, IIfS(puede, "playlist", "read"), id %>
  </div>
<%
End If
rs.Close
Set rs = Nothing
%>
</div>

<% If puede Then %>
<div class="section">
  <div class="section-head"><h2>Agregar cancion</h2></div>
  <form class="form-card" method="post" action="<%=FUrl("playlist-detail.asp")%>" style="max-width:640px">
    <input type="hidden" name="id_playlist" value="<%=id%>">
    <input type="hidden" name="accion" value="agregar">
    <div class="field">
      <label for="id_song">Cancion del catalogo</label>
      <select class="select" id="id_song" name="id_song" required>
        <option value="">-- Selecciona una cancion --</option>
        <%
        Dim rsDisp, hayDisponibles
        hayDisponibles = False
        Set rsDisp = DbRs(SongSelectSql("NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_SONG = s.ID_SONG AND ps.ID_PLAYLIST = " & id & ")", "s.SONG_NAME", 0))
        Do While Not rsDisp.EOF
          hayDisponibles = True
        %>
        <option value="<%=ToInt(rsDisp("ID_SONG"))%>"><%=H(F(rsDisp, "SONG_NAME"))%> &mdash; <%=H(F(rsDisp, "ARTISTS"))%></option>
        <%
          rsDisp.MoveNext
        Loop
        rsDisp.Close
        Set rsDisp = Nothing
        If Not hayDisponibles Then
        %>
        <option value="">(Todas las canciones ya estan en la playlist)</option>
        <%
        End If
        %>
      </select>
    </div>
    <div class="form-actions">
      <button class="btn btn-primary" type="submit"><%=Icon("plus")%>Agregar a la playlist</button>
    </div>
  </form>
</div>
<% End If %>
<%
RenderFrameBottom
CloseDb
%>

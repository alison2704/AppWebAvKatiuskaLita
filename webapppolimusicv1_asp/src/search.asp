<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  search.asp  -  Busqueda en canciones, albumes y artistas
' =====================================================================
RequireLogin
EnsureFrame

Dim termino, patron, nSongs, nAlbums, nArtists, rsSongs, rsAlbums, rsArtists

termino = Trim(CStr(Request.QueryString("q") & ""))
If Len(termino) > 100 Then termino = Left(termino, 100)
patron = "'%" & Replace(Replace(termino, "'", "''"), "[", "[[]") & "%'"

RenderFrameTop "Buscar", "search", "Encuentra canciones, albumes y artistas del catalogo."

If Len(termino) = 0 Then
%>
  <div class="empty">
    <%=Icon("search")%>
    <h3>Que quieres escuchar?</h3>
    <p>Escribe el nombre de una cancion, un album o un artista en la barra superior.</p>
  </div>
<%
Else

  nSongs   = DbCount("SELECT COUNT(*) FROM TBL_SONG s WHERE s.SONG_NAME LIKE " & patron)
  nAlbums  = DbCount("SELECT COUNT(*) FROM TBL_ALBUM al WHERE al.TITLE_ALBUM LIKE " & patron)
  nArtists = DbCount("SELECT COUNT(*) FROM TBL_ARTIST ar WHERE (ar.ARTIST_NAME LIKE " & patron & " OR ar.ARTIST_LASTNAME LIKE " & patron & ")")

  If nSongs + nAlbums + nArtists = 0 Then
%>
  <div class="empty">
    <%=Icon("search")%>
    <h3>Sin resultados para &laquo;<%=H(termino)%>&raquo;</h3>
    <p>Prueba con otras palabras o revisa la ortografia.</p>
    <a class="btn btn-ghost" href="home.asp?f=1">Volver al inicio</a>
  </div>
<%
  Else
%>

  <div class="stat-row">
    <div class="stat"><div class="k">Canciones</div><div class="v"><%=nSongs%></div></div>
    <div class="stat"><div class="k">Albumes</div><div class="v"><%=nAlbums%></div></div>
    <div class="stat"><div class="k">Artistas</div><div class="v"><%=nArtists%></div></div>
  </div>

<%  If nSongs > 0 Then %>
  <div class="section">
    <div class="section-head"><h2>Canciones</h2><span class="muted"><%=nSongs%> resultados</span></div>
    <div class="list">
      <% Set rsSongs = DbRs(SongSelectSql("s.SONG_NAME LIKE " & patron, "s.SONG_NAME", 30)) %>
      <% RenderTrackList rsSongs, "read", 0 %>
    </div>
  </div>
<%    rsSongs.Close : Set rsSongs = Nothing
  End If %>

<%  If nAlbums > 0 Then %>
  <div class="section">
    <div class="section-head"><h2>Albumes</h2><span class="muted"><%=nAlbums%> resultados</span></div>
    <div class="card-grid">
      <% Set rsAlbums = DbRs(AlbumSelectSql("al.TITLE_ALBUM LIKE " & patron, "al.TITLE_ALBUM", 18)) %>
      <% RenderAlbumCards rsAlbums %>
    </div>
  </div>
<%    rsAlbums.Close : Set rsAlbums = Nothing
  End If %>

<%  If nArtists > 0 Then %>
  <div class="section">
    <div class="section-head"><h2>Artistas</h2><span class="muted"><%=nArtists%> resultados</span></div>
    <div class="card-grid">
      <% Set rsArtists = DbRs(ArtistSelectSql("(ar.ARTIST_NAME LIKE " & patron & " OR ar.ARTIST_LASTNAME LIKE " & patron & ")", "ar.ARTIST_NAME", 18)) %>
      <% RenderArtistCards rsArtists %>
    </div>
  </div>
<%    rsArtists.Close : Set rsArtists = Nothing
  End If %>

<%
  End If
End If

RenderFrameBottom
CloseDb
%>

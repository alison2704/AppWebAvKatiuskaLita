<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  home.asp  -  Pantalla principal
' =====================================================================
RequireLogin
EnsureFrame

Dim rsHero, rsMine, rsAlbums, rsArtists, rsTop, heroId, heroTitle, heroImg, heroSub, heroType
Dim saludo

If Hour(Now()) < 12 Then
  saludo = "Buenos dias"
ElseIf Hour(Now()) < 19 Then
  saludo = "Buenas tardes"
Else
  saludo = "Buenas noches"
End If

' ---- Playlist destacada del usuario (o la ultima publica del sistema) ----
Set rsHero = DbRs(PlaylistSelectSql("pl.ID_USER = " & N(UserId()), "pl.CREATION_DATE DESC", 1))
If rsHero.EOF Then
  rsHero.Close
  Set rsHero = DbRs(PlaylistSelectSql("pl.TYPE = " & PL_PUBLIC, "pl.ID_PLAYLIST DESC", 1))
End If

RenderFrameTop "", "home", ""
%>

<div class="hero">
  <img class="hero-cover"
       src="<% If Not rsHero.EOF Then %><%=H(ImgPlaylist(F(rsHero, "PHOTO")))%><% Else %><%=Url(IMG_PLAYLIST_DEF)%><% End If %>"
       alt="Destacado">
  <div class="hero-body">
    <span class="hero-kicker"><%=H(saludo)%>, <%=H(Trunc(UserName(), 22))%></span>
    <h1 class="hero-title"><% If Not rsHero.EOF Then %><%=H(F(rsHero, "TITLE"))%><% Else %>Bienvenido a <%=H(APP_NAME)%><% End If %></h1>
    <div class="hero-meta">
<% If Not rsHero.EOF Then %>
      <span><%=H(F(rsHero, "USERNAME"))%></span>
      <span>&middot;</span>
      <span><%=ToInt(rsHero("SONGS"))%> canciones</span>
      <span>&middot;</span>
      <span class="badge <%=IIfS(ToInt(rsHero("TYPE")) = PL_PRIVATE, "badge-private", "badge-public")%>">
        <%=H(PlaylistTypeLabel(rsHero("TYPE")))%>
      </span>
<% Else %>
      <span>Explora el catalogo de canciones, albumes y artistas.</span>
<% End If %>
    </div>
    <div class="hero-actions">
<% If Not rsHero.EOF Then %>
      <a class="btn btn-primary" href="playlist-detail.asp?f=1&amp;id=<%=ToInt(rsHero("ID_PLAYLIST"))%>"><%=Icon("play")%>Abrir playlist</a>
<% End If %>
      <a class="btn btn-ghost" href="search.asp?f=1"><%=Icon("search")%>Explorar catalogo</a>
    </div>
  </div>
</div>
<%
If Not rsHero.EOF Then
  heroId = ToInt(rsHero("ID_PLAYLIST"))
End If
rsHero.Close
Set rsHero = Nothing
%>

<div class="stat-row">
  <div class="stat">
    <div class="k">Canciones</div>
    <div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_SONG")%></div>
  </div>
  <div class="stat">
    <div class="k">Albumes</div>
    <div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_ALBUM")%></div>
  </div>
  <div class="stat">
    <div class="k">Artistas</div>
    <div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_ARTIST")%></div>
  </div>
  <div class="stat">
    <div class="k">Playlists</div>
    <div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_PLAYLIST")%></div>
  </div>
</div>

<!-- ===================== Mis playlists ===================== -->
<div class="section">
  <div class="section-head">
    <h2>Mis playlists</h2>
    <a href="playlists.asp?f=1">Ver todas</a>
  </div>
<%
Set rsMine = DbRs(PlaylistSelectSql("pl.ID_USER = " & N(UserId()), "pl.CREATION_DATE DESC", 6))
If rsMine.EOF Then
  RenderEmpty "playlist", "Aun no tienes playlists", "Crea tu primera playlist y empieza a organizar tu musica.", "playlist-form.asp?f=1", "Nueva playlist"
Else
%>
  <div class="card-grid">
    <% RenderPlaylistCards rsMine %>
  </div>
<%
End If
rsMine.Close
Set rsMine = Nothing
%>
</div>

<!-- ===================== Albumes ===================== -->
<div class="section">
  <div class="section-head">
    <h2>Albumes</h2>
    <a href="albums.asp?f=1">Ver todos</a>
  </div>
<%
Set rsAlbums = DbRs(AlbumSelectSql("", "al.ID_ALBUM", 6))
%>
  <div class="card-grid">
    <% RenderAlbumCards rsAlbums %>
  </div>
<%
rsAlbums.Close
Set rsAlbums = Nothing
%>
</div>

<!-- ===================== Artistas ===================== -->
<div class="section">
  <div class="section-head">
    <h2>Artistas</h2>
    <a href="artists.asp?f=1">Ver todos</a>
  </div>
<%
Set rsArtists = DbRs(ArtistSelectSql("", "ar.ARTIST_NAME", 6))
%>
  <div class="card-grid">
    <% RenderArtistCards rsArtists %>
  </div>
<%
rsArtists.Close
Set rsArtists = Nothing
%>
</div>

<!-- ===================== Mas escuchadas ===================== -->
<div class="section">
  <div class="section-head">
    <h2>Canciones mas escuchadas</h2>
    <a href="songs.asp?f=1">Ver todas</a>
  </div>
<%
Set rsTop = DbRs(SongSelectSql("", "s.PLAYS DESC, s.SONG_NAME", 8))
%>
  <div class="list">
    <% RenderTrackList rsTop, "read", 0 %>
  </div>
<%
rsTop.Close
Set rsTop = Nothing
%>
</div>
<%
RenderFrameBottom
CloseDb
%>

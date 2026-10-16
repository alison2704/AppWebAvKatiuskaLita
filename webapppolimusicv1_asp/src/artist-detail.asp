<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  artist-detail.asp  -  Ficha de un artista con sus canciones y albumes
' =====================================================================
RequireLogin
EnsureFrame

Dim id, rs, nombre, img, nsongs, rsSongs, rsAlbums, accion

id = ToInt(Request.QueryString("id"))
If id <= 0 Then FlashRedirect "Artista no valido.", "error", "artists.asp"

Set rs = DbRs(ArtistSelectSql("ar.ID_ARTIST = " & id, "", 0))
If rs.EOF Then
  rs.Close
  FlashRedirect "El artista indicado no existe.", "error", "artists.asp"
End If

nombre  = ArtistNameOf(rs, "ARTIST_NAME", "ARTIST_LASTNAME")
img     = ImgArtist(F(rs, "ARTIST_IMAGE"))
nsongs  = ToInt(rs("SONGS"))
rs.Close
Set rs = Nothing

RenderFrameTop nombre, "artists", "Artista"
%>

<div class="hero">
  <img class="hero-cover" style="border-radius:50%" src="<%=H(img)%>" alt="<%=H(nombre)%>">
  <div class="hero-body">
    <span class="hero-kicker">Artista</span>
    <h1 class="hero-title"><%=H(nombre)%></h1>
    <div class="hero-meta">
      <span><%=nsongs%> canciones</span>
      <span>&middot;</span>
      <span><%=DbCount("SELECT COUNT(DISTINCT t.ID_ALBUM) FROM TBL_TRACKLIST t JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG WHERE p.ID_ARTIST = " & id)%> albumes</span>
    </div>
    <div class="hero-actions">
      <a class="btn btn-primary" href="artists.asp?f=1"><%=Icon("back")%>Volver a artistas</a>
      <% If IsAdmin() Then %>
        <a class="btn btn-ghost" href="artist-form.asp?f=1&amp;id=<%=id%>"><%=Icon("edit")%>Editar artista</a>
      <% End If %>
    </div>
  </div>
</div>

<div class="section">
  <div class="section-head"><h2>Canciones</h2><span class="muted"><%=nsongs%> en total</span></div>
<%
Set rsSongs = DbRs(SongSelectSql("EXISTS (SELECT 1 FROM TBL_PLAYER p WHERE p.ID_SONG = s.ID_SONG AND p.ID_ARTIST = " & id & ")", "s.SONG_NAME", 0))
%>
  <div class="list">
    <% RenderTrackList rsSongs, "read", 0 %>
  </div>
<%
rsSongs.Close
Set rsSongs = Nothing
%>
</div>

<div class="section">
  <div class="section-head"><h2>Albumes</h2></div>
<%
Set rsAlbums = DbRs(AlbumSelectSql( _
  "EXISTS (SELECT 1 FROM TBL_TRACKLIST t JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG " & _
  "WHERE t.ID_ALBUM = al.ID_ALBUM AND p.ID_ARTIST = " & id & ")", "al.RELEASE_YEAR DESC", 0))
If rsAlbums.EOF Then
  RenderEmpty "album", "Sin albumes", "Este artista todavia no tiene albumes asociados.", "", ""
Else
%>
  <div class="card-grid">
    <% RenderAlbumCards rsAlbums %>
  </div>
<%
End If
rsAlbums.Close
Set rsAlbums = Nothing
%>
</div>
<%
RenderFrameBottom
CloseDb
%>

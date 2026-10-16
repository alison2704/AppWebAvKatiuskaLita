<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  playlists.asp  -  Mis playlists y playlists publicas
' =====================================================================
RequireLogin
EnsureFrame

Dim rsMine, rsPublic, nMine, nPublic, wherePublico

RenderFrameTop "Playlists", "playlists", "Tus listas y las playlists publicas de la comunidad."
%>

<div class="row mb-24">
  <span class="grow"></span>
  <a class="btn btn-primary" href="playlist-form.asp?f=1"><%=Icon("plus")%>Nueva playlist</a>
</div>

<div class="section">
  <div class="section-head">
    <h2>Mis playlists</h2>
    <span class="muted"><%=DbCount("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = " & N(UserId()))%> listas</span>
  </div>
<%
Set rsMine = DbRs(PlaylistSelectSql("pl.ID_USER = " & N(UserId()), "pl.CREATION_DATE DESC", 0))
If rsMine.EOF Then
  RenderEmpty "playlist", "Todavia no tienes playlists", "Crea tu primera lista y agrega tus canciones favoritas.", "playlist-form.asp?f=1", "Crear playlist"
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

<div class="section">
  <div class="section-head">
    <h2>Playlists publicas</h2>
    <span class="muted"><%=DbCount("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE TYPE = " & PL_PUBLIC)%> listas</span>
  </div>
<%
wherePublico = "pl.TYPE = " & PL_PUBLIC
If Not IsAdmin() Then wherePublico = wherePublico & " AND pl.ID_USER <> " & N(UserId())
Set rsPublic = DbRs(PlaylistSelectSql(wherePublico, "pl.CREATION_DATE DESC", 0))
If rsPublic.EOF Then
  RenderEmpty "globe", "Sin playlists publicas", "Nadie mas ha publicado playlists todavia.", "", ""
Else
%>
  <div class="card-grid">
    <% RenderPlaylistCards rsPublic %>
  </div>
<%
End If
rsPublic.Close
Set rsPublic = Nothing
%>
</div>
<%
RenderFrameBottom
CloseDb
%>

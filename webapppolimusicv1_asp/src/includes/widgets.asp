<%
' =====================================================================
'  PoliMusic - Consultas reutilizables y componentes de interfaz
' =====================================================================

' --------------------------- SQL de canciones ------------------------
' Columnas: ID_SONG, SONG_NAME, SONG_PATH, PLAYS, COVER, ARTISTS
' topN > 0 -> TOP n
' Nota: VBScript NO admite parametros Optional, por eso existen dos
' variantes: la simple (3 argumentos) y la paginada (OFFSET/FETCH).
Function SongSelectSql(whereSql, orderSql, topN)
  SongSelectSql = SongSelectSqlPaged(whereSql, orderSql, topN, 0, 0)
End Function

Function SongSelectSqlPaged(whereSql, orderSql, topN, offset, limite)
  Dim s, off, lim
  off = ToInt(offset)
  lim = ToInt(limite)
  s = "SELECT "
  If lim > 0 Then
    If off < 0 Then off = 0
  ElseIf ToInt(topN) > 0 Then
    s = s & "TOP " & ToInt(topN) & " "
  End If
  s = s & "s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, " & _
      "ISNULL((SELECT TOP 1 al.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t " & _
      "        JOIN TBL_ALBUM al ON al.ID_ALBUM = t.ID_ALBUM " & _
      "        WHERE t.ID_SONG = s.ID_SONG ORDER BY al.ID_ALBUM),'') AS COVER, " & _
      "CAST(ISNULL((SELECT STRING_AGG(a.ARTIST_NAME + ISNULL(' ' + a.ARTIST_LASTNAME,''), ', ') " & _
      "             FROM TBL_PLAYER p JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
      "             WHERE p.ID_SONG = s.ID_SONG),'') AS varchar(1000)) AS ARTISTS " & _
      "FROM TBL_SONG s "
  If Len(whereSql) > 0 Then s = s & "WHERE " & whereSql & " "
  If Len(orderSql) > 0 Then s = s & "ORDER BY " & orderSql & " "
  If lim > 0 Then
    If Len(orderSql) = 0 Then s = s & "ORDER BY s.ID_SONG "
    s = s & "OFFSET " & off & " ROWS FETCH NEXT " & lim & " ROWS ONLY"
  End If
  SongSelectSqlPaged = s
End Function

' ---------------------------- SQL de albumes -------------------------
Function AlbumSelectSql(whereSql, orderSql, topN)
  AlbumSelectSql = AlbumSelectSqlPaged(whereSql, orderSql, topN, 0, 0)
End Function

Function AlbumSelectSqlPaged(whereSql, orderSql, topN, offset, limite)
  Dim s, off, lim
  off = ToInt(offset)
  lim = ToInt(limite)
  s = "SELECT "
  If lim > 0 Then
    If off < 0 Then off = 0
  ElseIf ToInt(topN) > 0 Then
    s = s & "TOP " & ToInt(topN) & " "
  End If
  s = s & "al.ID_ALBUM, al.TITLE_ALBUM, al.RELEASE_YEAR, al.ALBUM_IMAGE_PATH, " & _
      "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = al.ID_ALBUM) AS TRACKS, " & _
      "CAST(ISNULL((SELECT STRING_AGG(n.ARTISTA, ', ') " & _
      "             FROM (SELECT DISTINCT ar.ARTIST_NAME + ISNULL(' ' + ar.ARTIST_LASTNAME,'') AS ARTISTA " & _
      "                   FROM TBL_TRACKLIST t2 " & _
      "                   JOIN TBL_PLAYER p ON p.ID_SONG = t2.ID_SONG " & _
      "                   JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST " & _
      "                   WHERE t2.ID_ALBUM = al.ID_ALBUM) n),'') AS varchar(1000)) AS ARTISTS " & _
      "FROM TBL_ALBUM al "
  If Len(whereSql) > 0 Then s = s & "WHERE " & whereSql & " "
  If Len(orderSql) > 0 Then s = s & "ORDER BY " & orderSql & " "
  If lim > 0 Then
    If Len(orderSql) = 0 Then s = s & "ORDER BY al.ID_ALBUM "
    s = s & "OFFSET " & off & " ROWS FETCH NEXT " & lim & " ROWS ONLY"
  End If
  AlbumSelectSqlPaged = s
End Function

' ---------------------------- SQL de artistas ------------------------
Function ArtistSelectSql(whereSql, orderSql, topN)
  ArtistSelectSql = ArtistSelectSqlPaged(whereSql, orderSql, topN, 0, 0)
End Function

Function ArtistSelectSqlPaged(whereSql, orderSql, topN, offset, limite)
  Dim s, off, lim
  off = ToInt(offset)
  lim = ToInt(limite)
  s = "SELECT "
  If lim > 0 Then
    If off < 0 Then off = 0
  ElseIf ToInt(topN) > 0 Then
    s = s & "TOP " & ToInt(topN) & " "
  End If
  s = s & "ar.ID_ARTIST, ar.ARTIST_NAME, ar.ARTIST_LASTNAME, ar.ARTIST_IMAGE, " & _
      "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = ar.ID_ARTIST) AS SONGS " & _
      "FROM TBL_ARTIST ar "
  If Len(whereSql) > 0 Then s = s & "WHERE " & whereSql & " "
  If Len(orderSql) > 0 Then s = s & "ORDER BY " & orderSql & " "
  If lim > 0 Then
    If Len(orderSql) = 0 Then s = s & "ORDER BY ar.ID_ARTIST "
    s = s & "OFFSET " & off & " ROWS FETCH NEXT " & lim & " ROWS ONLY"
  End If
  ArtistSelectSqlPaged = s
End Function

' ---------------------------- SQL de playlists -----------------------
Function PlaylistSelectSql(whereSql, orderSql, topN)
  PlaylistSelectSql = PlaylistSelectSqlPaged(whereSql, orderSql, topN, 0, 0)
End Function

Function PlaylistSelectSqlPaged(whereSql, orderSql, topN, offset, limite)
  Dim s, off, lim
  off = ToInt(offset)
  lim = ToInt(limite)
  s = "SELECT "
  If lim > 0 Then
    If off < 0 Then off = 0
  ElseIf ToInt(topN) > 0 Then
    s = s & "TOP " & ToInt(topN) & " "
  End If
  s = s & "pl.ID_PLAYLIST, pl.ID_USER, pl.TITLE, pl.CREATION_DATE, pl.TYPE, pl.PHOTO, " & _
      "u.USERNAME, u.USER_PHOTO, " & _
      "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = pl.ID_PLAYLIST) AS SONGS " & _
      "FROM TBL_PLAYLIST pl JOIN TBL_USER u ON u.ID_USER = pl.ID_USER "
  If Len(whereSql) > 0 Then s = s & "WHERE " & whereSql & " "
  If Len(orderSql) > 0 Then s = s & "ORDER BY " & orderSql & " "
  If lim > 0 Then
    If Len(orderSql) = 0 Then s = s & "ORDER BY pl.ID_PLAYLIST "
    s = s & "OFFSET " & off & " ROWS FETCH NEXT " & lim & " ROWS ONLY"
  End If
  PlaylistSelectSqlPaged = s
End Function

' ------------------- atributo data-track (JSON) ----------------------
Function TrackAttr(id, titulo, artista, url, cover)
  Dim j
  j = "{""id"":" & ToInt(id) & _
      ",""title"":""" & Js(titulo) & """" & _
      ",""artist"":""" & Js(artista) & """" & _
      ",""url"":""" & Js(url) & """" & _
      ",""cover"":""" & Js(cover) & """}"
  TrackAttr = H(j)
End Function

Function ArtistNameOf(rs, campoNombre, campoApellido)
  Dim n, a
  n = Trim(F(rs, campoNombre))
  a = Trim(F(rs, campoApellido))
  ArtistNameOf = Trim(n & " " & a)
End Function

' =====================================================================
'  Lista de canciones
'  modo: "normal"  -> acciones de administrador
'        "playlist"-> boton quitar (ctxId = id de playlist)
'        "album"   -> boton quitar (ctxId = id de album)
'        "read"    -> solo lectura
' =====================================================================
Sub RenderTrackList(rs, modo, ctxId)
  Dim i, sid, cover, surl, artista, titulo, plays, attr
  If rs.EOF Then
    RenderEmpty "song", "Sin canciones", "Todavia no hay canciones en esta lista.", "", ""
    Exit Sub
  End If
  i = 0
  Do While Not rs.EOF
    sid     = ToInt(rs("ID_SONG"))
    titulo  = F(rs, "SONG_NAME")
    cover   = ImgAlbum(F(rs, "COVER"))
    surl    = SongUrl(F(rs, "SONG_PATH"))
    artista = F(rs, "ARTISTS")
    If Len(artista) = 0 Then artista = "Artista desconocido"
    plays   = ToInt(rs("PLAYS"))
    attr    = TrackAttr(sid, titulo, artista, surl, cover)
%>
  <div class="list-row" data-track="<%=attr%>">
    <div class="lr-num">
      <span class="num"><%=i + 1%></span>
      <span class="lr-play"><%=Icon("play")%></span>
    </div>
    <div class="lr-main">
      <img class="lr-art" src="<%=H(cover)%>" alt="" loading="lazy">
      <div class="lr-text">
        <span class="lr-title"><%=H(titulo)%></span>
        <span class="lr-sub"><%=H(artista)%></span>
      </div>
    </div>
    <div class="lr-right">
      <span class="lr-plays"><%=plays%> repro.</span>
<%
    If modo = "normal" Then
      If IsAdmin() Then
%>
      <a class="btn-icon" href="song-form.asp?f=1&amp;id=<%=sid%>" title="Editar cancion"><%=Icon("edit")%></a>
      <form method="post" action="songs.asp?f=1" data-confirm="Eliminar la cancion &quot;<%=H(titulo)%>&quot;? Se quitara tambien de albumes y playlists." style="display:inline">
        <input type="hidden" name="accion" value="eliminar">
        <input type="hidden" name="id" value="<%=sid%>">
        <button type="submit" class="btn-icon danger" title="Eliminar cancion"><%=Icon("trash")%></button>
      </form>
<%
      End If
    ElseIf modo = "playlist" Then
%>
      <form method="post" action="playlist-detail.asp?f=1" data-confirm="Quitar esta cancion de la playlist?" style="display:inline">
        <input type="hidden" name="accion" value="quitar">
        <input type="hidden" name="id_playlist" value="<%=ToInt(ctxId)%>">
        <input type="hidden" name="id_song" value="<%=sid%>">
        <button type="submit" class="btn-icon danger" title="Quitar de la playlist"><%=Icon("close")%></button>
      </form>
<%
    ElseIf modo = "album" Then
%>
      <form method="post" action="album-detail.asp?f=1" data-confirm="Quitar esta cancion del album?" style="display:inline">
        <input type="hidden" name="accion" value="quitar">
        <input type="hidden" name="id_album" value="<%=ToInt(ctxId)%>">
        <input type="hidden" name="id_song" value="<%=sid%>">
        <button type="submit" class="btn-icon danger" title="Quitar del album"><%=Icon("close")%></button>
      </form>
<%
    End If
%>
    </div>
  </div>
<%
    i = i + 1
    rs.MoveNext
  Loop
End Sub

' =====================================================================
'  Tarjetas
' =====================================================================
Sub RenderAlbumCards(rs)
  Dim aid, titulo, artista, img, anio, ntracks, href
  Do While Not rs.EOF
    aid     = ToInt(rs("ID_ALBUM"))
    titulo  = F(rs, "TITLE_ALBUM")
    artista = F(rs, "ARTISTS")
    If Len(artista) = 0 Then artista = "Artista desconocido"
    img     = ImgAlbum(F(rs, "ALBUM_IMAGE_PATH"))
    anio    = ToInt(rs("RELEASE_YEAR"))
    ntracks = ToInt(rs("TRACKS"))
    href    = "album-detail.asp?f=1&amp;id=" & aid
%>
  <article class="card">
    <div class="card-art">
      <img src="<%=H(img)%>" alt="<%=H(titulo)%>" loading="lazy">
    </div>
    <a class="card-link" href="<%=href%>" title="<%=H(titulo)%>"></a>
    <div class="card-title"><%=H(titulo)%></div>
    <div class="card-sub"><%=H(artista)%><%=IIfS(anio > 0, " &middot; " & anio, "")%> &middot; <%=ntracks%> temas</div>
<%
    If IsAdmin() Then
%>
    <div class="card-actions">
      <a class="btn-icon" href="album-form.asp?f=1&amp;id=<%=aid%>" title="Editar album"><%=Icon("edit")%></a>
    </div>
<%
    End If
%>
  </article>
<%
    rs.MoveNext
  Loop
End Sub

Sub RenderArtistCards(rs)
  Dim arid, nombre, img, nsongs, href
  Do While Not rs.EOF
    arid   = ToInt(rs("ID_ARTIST"))
    nombre = ArtistNameOf(rs, "ARTIST_NAME", "ARTIST_LASTNAME")
    img    = ImgArtist(F(rs, "ARTIST_IMAGE"))
    nsongs = ToInt(rs("SONGS"))
    href   = "artist-detail.asp?f=1&amp;id=" & arid
%>
  <article class="card">
    <div class="card-art round">
      <img src="<%=H(img)%>" alt="<%=H(nombre)%>" loading="lazy">
    </div>
    <a class="card-link" href="<%=href%>" title="<%=H(nombre)%>"></a>
    <div class="card-title"><%=H(nombre)%></div>
    <div class="card-sub"><%=nsongs%> canciones</div>
<%
    If IsAdmin() Then
%>
    <div class="card-actions">
      <a class="btn-icon" href="artist-form.asp?f=1&amp;id=<%=arid%>" title="Editar artista"><%=Icon("edit")%></a>
    </div>
<%
    End If
%>
  </article>
<%
    rs.MoveNext
  Loop
End Sub

Sub RenderPlaylistCards(rs)
  Dim pid, titulo, duenio, img, tipo, nsongs, href, esDuenio
  Do While Not rs.EOF
    pid     = ToInt(rs("ID_PLAYLIST"))
    titulo  = F(rs, "TITLE")
    duenio  = F(rs, "USERNAME")
    img     = ImgPlaylist(F(rs, "PHOTO"))
    tipo    = ToInt(rs("TYPE"))
    nsongs  = ToInt(rs("SONGS"))
    esDuenio = (ToInt(rs("ID_USER")) = UserId())
    href    = "playlist-detail.asp?f=1&amp;id=" & pid
%>
  <article class="card">
    <div class="card-art">
      <img src="<%=H(img)%>" alt="<%=H(titulo)%>" loading="lazy">
    </div>
    <a class="card-link" href="<%=href%>" title="<%=H(titulo)%>"></a>
    <div class="card-title"><%=H(titulo)%></div>
    <div class="card-sub">
      <% If tipo = PL_PRIVATE Then %><span class="badge badge-private"><%=Icon("lock")%>Privada</span> <% End If %>
      <%=H(duenio)%> &middot; <%=nsongs%> temas
    </div>
<%
    If IsAdmin() Or esDuenio Then
%>
    <div class="card-actions">
      <a class="btn-icon" href="playlist-form.asp?f=1&amp;id=<%=pid%>" title="Editar playlist"><%=Icon("edit")%></a>
    </div>
<%
    End If
%>
  </article>
<%
    rs.MoveNext
  Loop
End Sub

' =====================================================================
'  Estado vacio
' =====================================================================
Sub RenderEmpty(icono, titulo, texto, botonHref, botonTexto)
%>
  <div class="empty">
    <%=Icon(icono)%>
    <h3><%=H(titulo)%></h3>
    <p><%=H(texto)%></p>
<%  If Len(CStr("" & botonHref)) > 0 Then %>
    <a class="btn btn-primary" href="<%=botonHref%>"><%=Icon("plus")%><%=H(botonTexto)%></a>
<%  End If %>
  </div>
<%
End Sub

' Operador ternario simple para cadenas
Function IIfS(cond, valorSi, valorNo)
  If cond Then IIfS = valorSi Else IIfS = valorNo
End Function

' =====================================================================
'  Paginacion
' =====================================================================
Sub RenderPager(baseUrl, pagina, totalPaginas, totalRegistros)
  Dim p, ini, fin, i
  If totalPaginas <= 1 Then Exit Sub
  p = ToInt(pagina)
  If p < 1 Then p = 1
  If p > totalPaginas Then p = totalPaginas
%>
  <div class="pager">
    <span class="muted" style="border:0;background:transparent"><%=totalRegistros%> registros</span>
<%
  If p > 1 Then
%>
    <a href="<%=baseUrl%>&amp;pagina=<%=p - 1%>">Anterior</a>
<%
  Else
%>
    <span class="off">Anterior</span>
<%
  End If

  ini = p - 2
  If ini < 1 Then ini = 1
  fin = ini + 4
  If fin > totalPaginas Then fin = totalPaginas
  If fin - 4 > 1 Then ini = fin - 4
  If ini < 1 Then ini = 1

  For i = ini To fin
    If i = p Then
%>
    <span class="on"><%=i%></span>
<%
    Else
%>
    <a href="<%=baseUrl%>&amp;pagina=<%=i%>"><%=i%></a>
<%
    End If
  Next

  If p < totalPaginas Then
%>
    <a href="<%=baseUrl%>&amp;pagina=<%=p + 1%>">Siguiente</a>
<%
  Else
%>
    <span class="off">Siguiente</span>
<%
  End If
%>
  </div>
<%
End Sub
%>

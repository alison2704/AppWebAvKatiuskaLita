<%
' =====================================================================
'  PoliMusic - Layout: shell con reproductor persistente, barra
'  lateral, barra superior, iconos y mensajes flash.
'
'  Arquitectura de navegacion:
'    index.asp  -> shell (sidebar + reproductor + <iframe>)
'    paginas    -> se renderizan dentro del iframe con ?f=1
'  Asi el reproductor nunca se reinicia al navegar.
' =====================================================================

Dim PAGES_VALIDAS
PAGES_VALIDAS = ",home.asp,search.asp,songs.asp,song-form.asp,artists.asp,artist-detail.asp," & _
                "artist-form.asp,albums.asp,album-detail.asp,album-form.asp,playlists.asp," & _
                "playlist-form.asp,playlist-detail.asp,users.asp,user-form.asp,profile.asp,"

' Pagina valida para cargar dentro del shell
Function PaginaValida(nombre)
  Dim n
  n = LCase(Trim(CStr("" & nombre)))
  Do While Left(n, 1) = "/"
    n = Mid(n, 2)
  Loop
  PaginaValida = (InStr(1, PAGES_VALIDAS, "," & n & ",", 1) > 0)
End Function

' True cuando la pagina se esta renderizando dentro del iframe del shell
Function InFrame()
  InFrame = (LCase(CStr(Request.QueryString("f") & "")) = "1")
End Function

' Redirige al shell si la pagina se abrio directamente
Sub EnsureFrame()
  Dim t
  If InFrame() Then Exit Sub
  ' IMPORTANTE: en una peticion POST no se puede redirigir, porque el
  ' navegador descartaria los datos del formulario.  En ese caso la
  ' propia pagina procesa la accion y luego redirige con ?f=1.
  If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then Exit Sub
  t = Mid(CurrentUrl(), Len(AppRoot()) + 1)
  Response.Redirect Url("index.asp") & "?p=" & U(t)
  Response.End
End Sub

' Redirige manteniendo el modo iframe (agrega ?f=1)
Sub FrameRedirect(target)
  Dim t
  t = CStr("" & target)
  If InStr(t, "?") > 0 Then
    Response.Redirect Url(t) & "&f=1"
  Else
    Response.Redirect Url(t) & "?f=1"
  End If
  Response.End
End Sub

' Mensaje flash + redireccion en un solo paso
Sub FlashRedirect(msg, tipo, target)
  SetFlash msg, tipo
  FrameRedirect target
End Sub

' ------------------------- iconos SVG --------------------------------
Function Icon(nombre)
  Dim n, s
  n = LCase(Trim(CStr("" & nombre)))
  s = "<svg class=""ico"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" " & _
      "stroke-width=""1.9"" stroke-linecap=""round"" stroke-linejoin=""round"" aria-hidden=""true"">"
  Select Case n
    Case "home"
      s = s & "<path d=""M3 10.5 12 3l9 7.5""></path><path d=""M5 9.8V20a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V9.8""></path>"
    Case "search"
      s = s & "<circle cx=""11"" cy=""11"" r=""7""></circle><path d=""M20 20l-3.6-3.6""></path>"
    Case "library"
      s = s & "<path d=""M4 4h3v16H4zM9.5 4h3v16h-3z""></path><path d=""M15 5.6l3.4-.9 3.6 15.1-3.4.8z""></path>"
    Case "song"
      s = s & "<circle cx=""7"" cy=""18"" r=""3""></circle><circle cx=""18"" cy=""16"" r=""3""></circle><path=""M10 18V6l11-2v12""></path>"
    Case "album"
      s = s & "<circle cx=""12"" cy=""12"" r=""9""></circle><circle cx=""12"" cy=""12"" r=""2.6""></circle><path d=""M12 3v3""></path>"
    Case "artist"
      s = s & "<circle cx=""12"" cy=""8"" r=""4""></circle><path d=""M4.5 21a7.5 7.5 0 0 1 15 0""></path>"
    Case "playlist"
      s = s & "<path d=""M4 6h11M4 12h11M4 18h7""></path><circle cx=""18"" cy=""16"" r=""3""></circle><path d=""M21 16V8""></path>"
    Case "users"
      s = s & "<circle cx=""9"" cy=""8"" r=""3.4""></circle><path d=""M2.5 20a6.5 6.5 0 0 1 13 0""></path><path d=""M17 5.2a3.4 3.4 0 0 1 0 6.6""></path><path d=""M18.5 14.4A6.5 6.5 0 0 1 22 20""></path>"
    Case "logout"
      s = s & "<path d=""M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3""></path><path d=""M10 17l-5-5 5-5""></path><path d=""M5 12h10""></path>"
    Case "plus"
      s = s & "<path d=""M12 5v14M5 12h14""></path>"
    Case "edit"
      s = s & "<path d=""M4 20h4l10-10-4-4L4 16z""></path><path d=""M14.5 5.5l4 4""></path>"
    Case "trash"
      s = s & "<path d=""M4 7h16""></path><path d=""M9 7V5h6v2""></path><path d=""M6 7l1 13h10l1-13""></path>"
    Case "play"
      s = s & "<path d=""M7 4.5l13 7.5-13 7.5z"" fill=""currentColor"" stroke=""none""></path>"
    Case "pause"
      s = s & "<path d=""M8 5h3v14H8zM13 5h3v14h-3z"" fill=""currentColor"" stroke=""none""></path>"
    Case "prev"
      s = s & "<path d=""M18 5.5v13L8 12z"" fill=""currentColor"" stroke=""none""></path><path d=""M6 5v14""></path>"
    Case "next"
      s = s & "<path d=""M6 5.5v13L16 12z"" fill=""currentColor"" stroke=""none""></path><path d=""M18 5v14""></path>"
    Case "shuffle"
      s = s & "<path d=""M17 4h4v4""></path><path d=""M3 20l18-16""></path><path d=""M17 20h4v-4""></path><path d=""M3 4l6 5.3""></path><path d=""M14.5 14.5 21 20""></path>"
    Case "repeat"
      s = s & "<path d=""M17 2.5l3.5 3.5L17 9.5""></path><path d=""M3.5 12V10a4 4 0 0 1 4-4h13""></path><path d=""M7 21.5 3.5 18 7 14.5""></path><path d=""M20.5 12v2a4 4 0 0 1-4 4h-13""></path>"
    Case "volume"
      s = s & "<path d=""M4 9.5h3.5L12 5.5v13L7.5 14.5H4z""></path><path d=""M16 9a4.5 4.5 0 0 1 0 6""></path><path d=""M18.8 6.4a8 8 0 0 1 0 11.2""></path>"
    Case "mute"
      s = s & "<path d=""M4 9.5h3.5L12 5.5v13L7.5 14.5H4z""></path><path d=""M16.5 9.5l5 5M21.5 9.5l-5 5""></path>"
    Case "music"
      s = s & "<path d=""M9 18V5l12-2v13""></path><circle cx=""6"" cy=""18"" r=""3""></circle><circle cx=""18"" cy=""16"" r=""3""></circle>"
    Case "fire"
      s = s & "<path d=""M12 3s5 4.5 5 9a5 5 0 0 1-10 0c0-1.6.8-3 1.8-4.2.4 1.4 1.3 2.2 2.2 2.2.8 0 1.5-.6 1.5-1.7 0-1.6-.5-3.4-.5-5.3z""></path>"
    Case "heart"
      s = s & "<path d=""M12 20s-7-4.4-7-9.2A4 4 0 0 1 12 8a4 4 0 0 1 7 2.8C19 15.6 12 20 12 20z""></path>"
    Case "calendar"
      s = s & "<rect x=""3.5"" y=""5"" width=""17"" height=""15"" rx=""2""></rect><path d=""M3.5 10h17M8 3.5v3M16 3.5v3""></path>"
    Case "clock"
      s = s & "<circle cx=""12"" cy=""12"" r=""8.5""></circle><path d=""M12 7.5V12l3 2""></path>"
    Case "chevron"
      s = s & "<path d=""M9 5l7 7-7 7""></path>"
    Case "back"
      s = s & "<path d=""M15 19l-7-7 7-7""></path>"
    Case "close"
      s = s & "<path d=""M6 6l12 12M18 6L6 18""></path>"
    Case "check"
      s = s & "<path d=""M4.5 12.5l5 5 10-11""></path>"
    Case "lock"
      s = s & "<rect x=""4.5"" y=""10"" width=""15"" height=""10.5"" rx=""2""></rect><path d=""M8 10V7.5a4 4 0 0 1 8 0V10""></path>"
    Case "globe"
      s = s & "<circle cx=""12"" cy=""12"" r=""8.5""></circle><path d=""M3.5 12h17""></path><path d=""M12 3.5c2.4 2.4 3.6 5.3 3.6 8.5S14.4 18.1 12 20.5c-2.4-2.4-3.6-5.3-3.6-8.5S9.6 5.9 12 3.5z""></path>"
    Case "user"
      s = s & "<circle cx=""12"" cy=""8"" r=""3.6""></circle><path d=""M5 20a7 7 0 0 1 14 0""></path>"
    Case Else
      s = s & "<circle cx=""12"" cy=""12"" r=""9""></circle>"
  End Select
  Icon = s & "</svg>"
End Function

' --------------------------- mensajes flash ---------------------------
Sub RenderFlash()
  Dim m, t
  m = TakeFlashMsg()
  t = TakeFlashTipo()
  If Len(m) = 0 Then Exit Sub
  If Len(t) = 0 Then t = "ok"
%>
  <div class="flash flash-<%=H(t)%>" id="flashBox">
    <span class="flash-ico"><%=Icon("check")%></span>
    <span><%=H(m)%></span>
    <button type="button" class="flash-x" onclick="this.parentNode.remove()">&times;</button>
  </div>
<%
End Sub

' --------------------- cabecera comun (head) --------------------------
Sub RenderHead(titulo)
%><!DOCTYPE html>
<html lang="es" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><% If Len(Trim(CStr("" & titulo))) > 0 Then %><%=H(titulo)%> &middot; <% End If %><%=H(APP_NAME)%></title>
<link rel="icon" href="<%=Url("UserImages/root.png")%>">
<link rel="stylesheet" href="<%=Url("css/style.css")%>">
</head>
<%
End Sub

' =====================================================================
'  SHELL  (index.asp)
' =====================================================================
Sub RenderShellTop(activo, frameSrc)
%><body class="shell">
<div class="app">
  <aside class="sidebar">
    <div class="brand">
      <span class="brand-mark"><%=Icon("music")%></span>
      <span class="brand-text">
        <strong><%=H(APP_NAME)%></strong>
        <small>Music</small>
      </span>
    </div>

    <nav class="nav" id="mainNav">
      <a class="nav-item" data-key="home" href="home.asp?f=1" target="appFrame"><%=Icon("home")%><span>Inicio</span></a>
      <a class="nav-item" data-key="search" href="search.asp?f=1" target="appFrame"><%=Icon("search")%><span>Buscar</span></a>

      <div class="nav-title">Tu biblioteca</div>
      <a class="nav-item" data-key="playlists" href="playlists.asp?f=1" target="appFrame"><%=Icon("playlist")%><span>Playlists</span></a>
      <a class="nav-item" data-key="songs" href="songs.asp?f=1" target="appFrame"><%=Icon("song")%><span>Canciones</span></a>
      <a class="nav-item" data-key="albums" href="albums.asp?f=1" target="appFrame"><%=Icon("album")%><span>Albumes</span></a>
      <a class="nav-item" data-key="artists" href="artists.asp?f=1" target="appFrame"><%=Icon("artist")%><span>Artistas</span></a>
<%
  If IsAdmin() Then
%>
      <div class="nav-title">Administracion</div>
      <a class="nav-item" data-key="users" href="users.asp?f=1" target="appFrame"><%=Icon("users")%><span>Usuarios</span></a>
<%
  End If
%>
    </nav>

    <div class="sidebar-user">
      <img src="<%=ImgUser(UserPhoto())%>" alt="avatar">
      <div class="su-info">
        <strong title="<%=H(UserName())%>"><%=H(Trunc(UserName(), 18))%></strong>
        <small><%=H(RoleLabel(UserType()))%></small>
      </div>
      <a class="su-out" href="logout.asp" title="Cerrar sesion"><%=Icon("logout")%></a>
    </div>
  </aside>

  <main class="main">
    <header class="topbar">
      <div class="tb-nav">
        <button type="button" class="tb-round" onclick="frameGo(-1)" title="Atras"><%=Icon("back")%></button>
        <button type="button" class="tb-round" onclick="frameGo(1)" title="Adelante"><%=Icon("chevron")%></button>
      </div>
      <form class="tb-search" action="search.asp" method="get" target="appFrame" autocomplete="off">
        <input type="hidden" name="f" value="1">
        <span class="tb-search-ico"><%=Icon("search")%></span>
        <input type="text" name="q" placeholder="Que quieres escuchar?" id="topSearch">
      </form>
      <div class="tb-user">
        <button type="button" class="tb-theme" id="themeToggle" title="Cambiar tema">&#9788;</button>
        <a class="tb-profile" href="profile.asp?f=1" target="appFrame">
          <img src="<%=ImgUser(UserPhoto())%>" alt="avatar">
          <span><%=H(Trunc(UserName(), 16))%></span>
        </a>
        <a class="tb-logout" href="logout.asp" title="Cerrar sesion"><%=Icon("logout")%><span>Salir</span></a>
      </div>
    </header>
    <div class="frame-wrap">
      <iframe class="frame" name="appFrame" id="appFrame" src="<%=H(frameSrc)%>" title="Contenido"></iframe>
    </div>
  </main>
</div>
<%
End Sub

Sub RenderShellBottom()
%>
<%=RenderPlayerMarkup()%>
<script src="<%=Url("js/app.js")%>"></script>
</body>
</html>
<%
End Sub

' =====================================================================
'  PAGINAS DENTRO DEL IFRAME  (?f=1)
' =====================================================================
Sub RenderFrameTop(titulo, activo, subtitulo)
  RenderHead titulo
%><body class="framed">
<div class="page" data-active="<%=H(activo)%>">
<%
  If Len(CStr("" & titulo)) > 0 Then
%>
  <div class="page-head">
    <div>
      <h1 class="page-title"><%=H(titulo)%></h1>
      <% If Len(CStr("" & subtitulo)) > 0 Then %><p class="page-sub"><%=subtitulo%></p><% End If %>
    </div>
    <div class="page-actions" id="pageActions"></div>
  </div>
<%
  End If
  RenderFlash
End Sub

Sub RenderFrameBottom()
%>
</div>
<script src="<%=Url("js/app.js")%>"></script>
</body>
</html>
<%
End Sub

' =====================================================================
'  PAGINAS AUTONOMAS (login, registro, errores)
' =====================================================================
Sub RenderStandaloneTop(titulo)
  RenderHead titulo
%><body class="standalone">
<%
End Sub

Sub RenderStandaloneBottom()
%>
<script src="<%=Url("js/app.js")%>"></script>
</body>
</html>
<%
End Sub

' =====================================================================
'  REPRODUCTOR (barra inferior persistente)
' =====================================================================
Function RenderPlayerMarkup()
  Dim s
  s = "" & _
  "<div class=""player"" id=""player"">" & _
  "  <div class=""pl-left"">" & _
  "    <div class=""pl-cover"" id=""plCover""><span>" & Icon("music") & "</span></div>" & _
  "    <div class=""pl-meta"">" & _
  "      <a class=""pl-title"" id=""plTitle"" href=""javascript:void(0)"">&mdash;</a>" & _
  "      <span class=""pl-artist"" id=""plArtist"">Selecciona una cancion</span>" & _
  "    </div>" & _
  "    <button type=""button"" class=""pl-heart"" id=""plHeart"" title=""Favorito"">" & Icon("heart") & "</button>" & _
  "  </div>" & _
  "  <div class=""pl-center"">" & _
  "    <div class=""pl-controls"">" & _
  "      <button type=""button"" class=""pc-btn"" id=""plShuffle"" title=""Aleatorio"">" & Icon("shuffle") & "</button>" & _
  "      <button type=""button"" class=""pc-btn"" id=""plPrev"" title=""Anterior"">" & Icon("prev") & "</button>" & _
  "      <button type=""button"" class=""pc-play"" id=""plPlay"" title=""Reproducir"">" & Icon("play") & "</button>" & _
  "      <button type=""button"" class=""pc-btn"" id=""plNext"" title=""Siguiente"">" & Icon("next") & "</button>" & _
  "      <button type=""button"" class=""pc-btn"" id=""plRepeat"" title=""Repetir"">" & Icon("repeat") & "</button>" & _
  "    </div>" & _
  "    <div class=""pl-progress"">" & _
  "      <span id=""plCur"">0:00</span>" & _
  "      <input type=""range"" id=""plSeek"" min=""0"" max=""1000"" value=""0"" step=""1"" aria-label=""Progreso"">" & _
  "      <span id=""plDur"">0:00</span>" & _
  "    </div>" & _
  "  </div>" & _
  "  <div class=""pl-right"">" & _
  "    <button type=""button"" class=""pc-btn"" id=""plMute"" title=""Silenciar"">" & Icon("volume") & "</button>" & _
  "    <input type=""range"" id=""plVol"" min=""0"" max=""100"" value=""85"" aria-label=""Volumen"">" & _
  "    <span class=""pl-badge"" id=""plCount"">0 canciones</span>" & _
  "  </div>" & _
  "  <audio id=""plAudio"" preload=""metadata""></audio>" & _
  "</div>"
  RenderPlayerMarkup = s
End Function
%>

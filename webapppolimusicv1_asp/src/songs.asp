<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  songs.asp  -  Catalogo de canciones
'  Lectura para todos.  Eliminacion solo para administradores.
' =====================================================================
RequireLogin
EnsureFrame

Const POR_PAGINA = 10

Dim accion, id, pagina, filtro, whereSql, total, totalPaginas, offset, rs, baseUrl, orden

' ------------------------------ POST: eliminar ------------------------
If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
  If Not IsAdmin() Then
    FlashRedirect "No tienes permisos para eliminar canciones.", "error", "songs.asp"
  End If

  accion = FormVal("accion")
  id     = ToInt(FormVal("id"))
  pagina = ToInt(FormVal("pagina"))
  If pagina < 1 Then pagina = 1

  If accion = "eliminar" And id > 0 Then
    Dim nombre
    nombre = CStr(DbScalar("SELECT SONG_NAME FROM TBL_SONG WHERE ID_SONG = " & id, ""))
    If Len(nombre) > 0 Then
      ' Se eliminan primero las referencias para respetar las claves foraneas
      DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = " & id
      DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = " & id
      DbExec "DELETE FROM TBL_PLAYER WHERE ID_SONG = " & id
      DbExec "DELETE FROM TBL_SONG WHERE ID_SONG = " & id
      FlashRedirect "Cancion """ & nombre & """ eliminada correctamente.", "ok", "songs.asp?pagina=" & pagina
    Else
      FlashRedirect "La cancion indicada no existe.", "error", "songs.asp?pagina=" & pagina
    End If
  Else
    FlashRedirect "Accion no reconocida.", "error", "songs.asp"
  End If
End If

' ------------------------------- GET ----------------------------------
pagina = ToInt(Request.QueryString("pagina"))
If pagina < 1 Then pagina = 1
filtro = Trim(CStr(Request.QueryString("q") & ""))
If Len(filtro) > 80 Then filtro = Left(filtro, 80)

whereSql = ""
If Len(filtro) > 0 Then whereSql = "s.SONG_NAME LIKE '%" & Replace(Replace(filtro, "'", "''"), "[", "[[]") & "%'"

total = DbCount("SELECT COUNT(*) FROM TBL_SONG s" & IIfS(Len(whereSql) > 0, " WHERE " & whereSql, ""))
totalPaginas = Int((total + POR_PAGINA - 1) / POR_PAGINA)
If totalPaginas < 1 Then totalPaginas = 1
If pagina > totalPaginas Then pagina = totalPaginas
offset = (pagina - 1) * POR_PAGINA

baseUrl = "songs.asp?f=1"
If Len(filtro) > 0 Then baseUrl = baseUrl & "&amp;q=" & U(filtro)

RenderFrameTop "Canciones", "songs", "Todas las canciones disponibles en el catalogo."
%>

<div class="row mb-24">
  <form class="row" method="get" action="<%=Url("songs.asp")%>" style="gap:8px">
    <input type="hidden" name="f" value="1">
    <input class="input" type="text" name="q" value="<%=H(filtro)%>" placeholder="Filtrar por nombre de cancion..." style="min-width:260px">
    <button class="btn btn-ghost" type="submit"><%=Icon("search")%>Filtrar</button>
    <% If Len(filtro) > 0 Then %>
      <a class="btn btn-ghost" href="songs.asp?f=1"><%=Icon("close")%>Limpiar</a>
    <% End If %>
  </form>
</div>

<div class="page-actions" id="pageActionsInner">
  <% If IsAdmin() Then %>
    <a class="btn btn-primary" href="song-form.asp?f=1"><%=Icon("plus")%>Nueva cancion</a>
  <% End If %>
</div>

<%
Set rs = DbRs(SongSelectSqlPaged(whereSql, "s.SONG_NAME", 0, offset, POR_PAGINA))
%>
<div class="list" style="margin-top:16px">
  <% RenderTrackList rs, "normal", 0 %>
</div>
<%
rs.Close
Set rs = Nothing

RenderPager baseUrl, pagina, totalPaginas, total

RenderFrameBottom
CloseDb
%>

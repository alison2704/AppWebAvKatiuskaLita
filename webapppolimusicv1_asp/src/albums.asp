<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  albums.asp  -  Catalogo de albumes
' =====================================================================
RequireLogin
EnsureFrame

Const POR_PAGINA = 12

Dim accion, id, pagina, filtro, whereSql, total, totalPaginas, offset, rs, baseUrl, titulo

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
  If Not IsAdmin() Then
    FlashRedirect "No tienes permisos para eliminar albumes.", "error", "albums.asp"
  End If
  accion = FormVal("accion")
  id     = ToInt(FormVal("id"))
  pagina = ToInt(FormVal("pagina"))
  If pagina < 1 Then pagina = 1

  If accion = "eliminar" And id > 0 Then
    titulo = CStr(DbScalar("SELECT TITLE_ALBUM FROM TBL_ALBUM WHERE ID_ALBUM = " & id, ""))
    If Len(titulo) > 0 Then
      DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = " & id
      DbExec "DELETE FROM TBL_ALBUM WHERE ID_ALBUM = " & id
      FlashRedirect "Album """ & titulo & """ eliminado correctamente.", "ok", "albums.asp?pagina=" & pagina
    Else
      FlashRedirect "El album indicado no existe.", "error", "albums.asp?pagina=" & pagina
    End If
  Else
    FlashRedirect "Accion no reconocida.", "error", "albums.asp"
  End If
End If

pagina = ToInt(Request.QueryString("pagina"))
If pagina < 1 Then pagina = 1
filtro = Trim(CStr(Request.QueryString("q") & ""))
If Len(filtro) > 80 Then filtro = Left(filtro, 80)

whereSql = ""
If Len(filtro) > 0 Then whereSql = "al.TITLE_ALBUM LIKE '%" & Replace(Replace(filtro, "'", "''"), "[", "[[]") & "%'"

total = DbCount("SELECT COUNT(*) FROM TBL_ALBUM al" & IIfS(Len(whereSql) > 0, " WHERE " & whereSql, ""))
totalPaginas = Int((total + POR_PAGINA - 1) / POR_PAGINA)
If totalPaginas < 1 Then totalPaginas = 1
If pagina > totalPaginas Then pagina = totalPaginas
offset = (pagina - 1) * POR_PAGINA

baseUrl = "albums.asp?f=1"
If Len(filtro) > 0 Then baseUrl = baseUrl & "&amp;q=" & U(filtro)

RenderFrameTop "Albumes", "albums", "Discografia disponible en el catalogo."
%>

<div class="row mb-24">
  <form class="row" method="get" action="<%=Url("albums.asp")%>" style="gap:8px">
    <input type="hidden" name="f" value="1">
    <input class="input" type="text" name="q" value="<%=H(filtro)%>" placeholder="Filtrar por titulo de album..." style="min-width:260px">
    <button class="btn btn-ghost" type="submit"><%=Icon("search")%>Filtrar</button>
    <% If Len(filtro) > 0 Then %>
      <a class="btn btn-ghost" href="albums.asp?f=1"><%=Icon("close")%>Limpiar</a>
    <% End If %>
  </form>
  <span class="grow"></span>
  <% If IsAdmin() Then %>
    <a class="btn btn-primary" href="album-form.asp?f=1"><%=Icon("plus")%>Nuevo album</a>
  <% End If %>
</div>

<%
Set rs = DbRs(AlbumSelectSqlPaged(whereSql, "al.RELEASE_YEAR DESC, al.TITLE_ALBUM", 0, offset, POR_PAGINA))
If rs.EOF Then
  RenderEmpty "album", "Sin albumes", "No se encontraron albumes con esos criterios.", "", ""
Else
%>
<div class="card-grid">
  <% RenderAlbumCards rs %>
</div>
<%
End If
rs.Close
Set rs = Nothing

RenderPager baseUrl, pagina, totalPaginas, total

RenderFrameBottom
CloseDb
%>

<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  artists.asp  -  Catalogo de artistas
' =====================================================================
RequireLogin
EnsureFrame

Const POR_PAGINA = 12

Dim accion, id, pagina, filtro, whereSql, total, totalPaginas, offset, rs, baseUrl, nombre

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
  If Not IsAdmin() Then
    FlashRedirect "No tienes permisos para eliminar artistas.", "error", "artists.asp"
  End If
  accion = FormVal("accion")
  id     = ToInt(FormVal("id"))
  pagina = ToInt(FormVal("pagina"))
  If pagina < 1 Then pagina = 1

  If accion = "eliminar" And id > 0 Then
    nombre = Trim(CStr(DbScalar("SELECT ARTIST_NAME + ' ' + ISNULL(ARTIST_LASTNAME,'') FROM TBL_ARTIST WHERE ID_ARTIST = " & id, "")))
    If Len(nombre) > 0 Then
      DbExec "DELETE FROM TBL_PLAYER WHERE ID_ARTIST = " & id
      DbExec "DELETE FROM TBL_ARTIST WHERE ID_ARTIST = " & id
      FlashRedirect "Artista """ & nombre & """ eliminado correctamente.", "ok", "artists.asp?pagina=" & pagina
    Else
      FlashRedirect "El artista indicado no existe.", "error", "artists.asp?pagina=" & pagina
    End If
  Else
    FlashRedirect "Accion no reconocida.", "error", "artists.asp"
  End If
End If

pagina = ToInt(Request.QueryString("pagina"))
If pagina < 1 Then pagina = 1
filtro = Trim(CStr(Request.QueryString("q") & ""))
If Len(filtro) > 80 Then filtro = Left(filtro, 80)

whereSql = ""
If Len(filtro) > 0 Then
  Dim patron
  patron = "'%" & Replace(Replace(filtro, "'", "''"), "[", "[[]") & "%'"
  whereSql = "(ar.ARTIST_NAME LIKE " & patron & " OR ar.ARTIST_LASTNAME LIKE " & patron & ")"
End If

total = DbCount("SELECT COUNT(*) FROM TBL_ARTIST ar" & IIfS(Len(whereSql) > 0, " WHERE " & whereSql, ""))
totalPaginas = Int((total + POR_PAGINA - 1) / POR_PAGINA)
If totalPaginas < 1 Then totalPaginas = 1
If pagina > totalPaginas Then pagina = totalPaginas
offset = (pagina - 1) * POR_PAGINA

baseUrl = "artists.asp?f=1"
If Len(filtro) > 0 Then baseUrl = baseUrl & "&amp;q=" & U(filtro)

RenderFrameTop "Artistas", "artists", "Todos los artistas registrados en la plataforma."
%>

<div class="row mb-24">
  <form class="row" method="get" action="<%=Url("artists.asp")%>" style="gap:8px">
    <input type="hidden" name="f" value="1">
    <input class="input" type="text" name="q" value="<%=H(filtro)%>" placeholder="Filtrar por nombre o apellido..." style="min-width:260px">
    <button class="btn btn-ghost" type="submit"><%=Icon("search")%>Filtrar</button>
    <% If Len(filtro) > 0 Then %>
      <a class="btn btn-ghost" href="artists.asp?f=1"><%=Icon("close")%>Limpiar</a>
    <% End If %>
  </form>
  <span class="grow"></span>
  <% If IsAdmin() Then %>
    <a class="btn btn-primary" href="artist-form.asp?f=1"><%=Icon("plus")%>Nuevo artista</a>
  <% End If %>
</div>

<%
Set rs = DbRs(ArtistSelectSqlPaged(whereSql, "ar.ARTIST_NAME, ar.ARTIST_LASTNAME", 0, offset, POR_PAGINA))
If rs.EOF Then
  RenderEmpty "artist", "Sin artistas", "No se encontraron artistas con esos criterios.", "", ""
Else
%>
<div class="card-grid">
  <% RenderArtistCards rs %>
</div>
<%
End If
rs.Close
Set rs = Nothing

RenderPager baseUrl, pagina, totalPaginas, total

RenderFrameBottom
CloseDb
%>

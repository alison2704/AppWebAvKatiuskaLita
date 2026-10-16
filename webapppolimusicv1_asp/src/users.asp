<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  users.asp  -  Administracion de usuarios  (solo ADMIN)
' =====================================================================
RequireAdmin
EnsureFrame

Const POR_PAGINA = 12

Dim accion, id, pagina, filtro, whereSql, total, totalPaginas, offset, rs, baseUrl, nombre, nPlaylists

If UCase(CStr(Request.ServerVariables("REQUEST_METHOD"))) = "POST" Then
  accion = FormVal("accion")
  id     = ToInt(FormVal("id"))
  pagina = ToInt(FormVal("pagina"))
  If pagina < 1 Then pagina = 1

  If accion = "eliminar" And id > 0 Then
    If id = UserId() Then
      FlashRedirect "No puedes eliminar tu propia cuenta mientras estas conectado.", "error", "users.asp?pagina=" & pagina
    End If
    nombre = CStr(DbScalar("SELECT USERNAME FROM TBL_USER WHERE ID_USER = " & id, ""))
    If Len(nombre) = 0 Then
      FlashRedirect "El usuario indicado no existe.", "error", "users.asp?pagina=" & pagina
    End If
    ' Se eliminan primero sus playlists para respetar la clave foranea
    DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST IN (SELECT ID_PLAYLIST FROM TBL_PLAYLIST WHERE ID_USER = " & id & ")"
    DbExec "DELETE FROM TBL_PLAYLIST WHERE ID_USER = " & id
    DbExec "DELETE FROM TBL_USER WHERE ID_USER = " & id
    FlashRedirect "Usuario """ & nombre & """ eliminado correctamente.", "ok", "users.asp?pagina=" & pagina
  Else
    FlashRedirect "Accion no reconocida.", "error", "users.asp"
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
  whereSql = "(USERNAME LIKE " & patron & " OR EMAIL LIKE " & patron & ")"
End If

total = DbCount("SELECT COUNT(*) FROM TBL_USER" & IIfS(Len(whereSql) > 0, " WHERE " & whereSql, ""))
totalPaginas = Int((total + POR_PAGINA - 1) / POR_PAGINA)
If totalPaginas < 1 Then totalPaginas = 1
If pagina > totalPaginas Then pagina = totalPaginas
offset = (pagina - 1) * POR_PAGINA

baseUrl = "users.asp?f=1"
If Len(filtro) > 0 Then baseUrl = baseUrl & "&amp;q=" & U(filtro)

RenderFrameTop "Usuarios", "users", "Gestion de cuentas, roles y playlists de los usuarios."
%>

<div class="stat-row">
  <div class="stat"><div class="k">Usuarios totales</div><div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_USER")%></div></div>
  <div class="stat"><div class="k">Administradores</div><div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = " & ROLE_ADMIN)%></div></div>
  <div class="stat"><div class="k">Usuarios normales</div><div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = " & ROLE_USER)%></div></div>
  <div class="stat"><div class="k">Playlists</div><div class="v"><%=DbCount("SELECT COUNT(*) FROM TBL_PLAYLIST")%></div></div>
</div>

<div class="row mb-24">
  <form class="row" method="get" action="<%=FUrl("users.asp")%>" style="gap:8px">
    <input type="hidden" name="f" value="1">
    <input class="input" type="text" name="q" value="<%=H(filtro)%>" placeholder="Filtrar por usuario o correo..." style="min-width:260px">
    <button class="btn btn-ghost" type="submit"><%=Icon("search")%>Filtrar</button>
    <% If Len(filtro) > 0 Then %>
      <a class="btn btn-ghost" href="users.asp?f=1"><%=Icon("close")%>Limpiar</a>
    <% End If %>
  </form>
  <span class="grow"></span>
  <a class="btn btn-primary" href="user-form.asp?f=1"><%=Icon("plus")%>Nuevo usuario</a>
</div>

<div class="table-wrap">
  <table class="data">
    <thead>
      <tr>
        <th>Usuario</th>
        <th>Correo</th>
        <th>Cumpleanios</th>
        <th>Rol</th>
        <th>Playlists</th>
        <th style="text-align:right">Acciones</th>
      </tr>
    </thead>
    <tbody>
<%
Set rs = DbRs("SELECT ID_USER, USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER " & _
              IIfS(Len(whereSql) > 0, "WHERE " & whereSql & " ", "") & _
              "ORDER BY USER_TYPE DESC, USERNAME " & _
              "OFFSET " & offset & " ROWS FETCH NEXT " & POR_PAGINA & " ROWS ONLY")

If rs.EOF Then
%>
      <tr><td colspan="6" class="center muted" style="padding:34px">No se encontraron usuarios.</td></tr>
<%
End If

Do While Not rs.EOF
  Dim uid, uname, uemail, ubirth, uphoto, utype, uplay
  uid    = ToInt(rs("ID_USER"))
  uname  = F(rs, "USERNAME")
  uemail = F(rs, "EMAIL")
  ubirth = F(rs, "BIRTHDAY")
  uphoto = F(rs, "USER_PHOTO")
  utype  = ToInt(rs("USER_TYPE"))
  uplay  = DbCount("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = " & uid)
%>
      <tr>
        <td>
          <div class="cell-user">
            <img src="<%=H(ImgUser(uphoto))%>" alt="">
            <div>
              <div style="font-weight:600"><%=H(uname)%></div>
              <div class="muted" style="font-size:12px">ID <%=uid%><% If uid = UserId() Then %> &middot; (tu cuenta)<% End If %></div>
            </div>
          </div>
        </td>
        <td><%=H(uemail)%></td>
        <td class="num"><%=H(FormatDate(ubirth))%><% If Len(FormatDate(ubirth)) > 0 Then %> <span class="muted">(<%=Age(ubirth)%> anios)</span><% End If %></td>
        <td>
          <span class="badge <%=IIfS(utype = ROLE_ADMIN, "badge-admin", "badge-user")%>">
            <%=Icon(IIfS(utype = ROLE_ADMIN, "lock", "user"))%><%=H(RoleLabel(utype))%>
          </span>
        </td>
        <td class="num"><%=uplay%></td>
        <td>
          <div class="cell-actions">
            <a class="btn-icon" href="user-form.asp?f=1&amp;id=<%=uid%>" title="Editar usuario"><%=Icon("edit")%></a>
<% If uid <> UserId() Then %>
            <form method="post" action="<%=FUrl("users.asp")%>" style="display:inline"
                  data-confirm="Eliminar al usuario &quot;<%=H(uname)%>&quot;? Se eliminaran tambien sus <%=uplay%> playlists.">
              <input type="hidden" name="accion" value="eliminar">
              <input type="hidden" name="id" value="<%=uid%>">
              <input type="hidden" name="pagina" value="<%=pagina%>">
              <button type="submit" class="btn-icon danger" title="Eliminar usuario"><%=Icon("trash")%></button>
            </form>
<% End If %>
          </div>
        </td>
      </tr>
<%
  rs.MoveNext
Loop
rs.Close
Set rs = Nothing
%>
    </tbody>
  </table>
</div>
<%
RenderPager baseUrl, pagina, totalPaginas, total

RenderFrameBottom
CloseDb
%>

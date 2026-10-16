<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  index.asp  -  Shell de la aplicacion
'  Contiene la barra lateral, la barra superior y el reproductor
'  persistente.  El contenido se carga dentro de un <iframe> para que
'  la musica no se detenga al navegar.
' =====================================================================
RequireLogin

Dim pagina, resto, qs, pos, frameSrc

pagina = Trim(CStr(Request.QueryString("p") & ""))
If Len(pagina) = 0 Then pagina = "home.asp"

' La pagina puede venir como "playlist-detail.asp?id=3"
pos = InStr(pagina, "?")
If pos > 0 Then
  qs = Mid(pagina, pos + 1)
  pagina = Left(pagina, pos - 1)
Else
  qs = ""
End If

If Not PaginaValida(pagina) Then
  pagina = "home.asp"
  qs = ""
End If

frameSrc = pagina & "?f=1"
If Len(qs) > 0 Then frameSrc = frameSrc & "&" & qs

RenderHead "Inicio"
RenderShellTop "home", frameSrc
RenderShellBottom
CloseDb
%>

<!--#include file="includes/init.asp"-->
<%
' Punto de entrada de la aplicacion
If IsLoggedIn() Then
  Response.Redirect Url("index.asp")
Else
  Response.Redirect Url("login.asp")
End If
Response.End
%>

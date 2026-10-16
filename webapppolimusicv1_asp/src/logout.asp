<!--#include file="includes/init.asp"-->
<%
' Cierre de sesion
DoLogout
Response.Redirect Url("login.asp")
Response.End
%>

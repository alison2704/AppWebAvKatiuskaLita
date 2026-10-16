<!--#include file="includes/init.asp"-->
<%
' =====================================================================
'  api-play.asp  -  Incrementa el contador de reproducciones
'  Se invoca desde el reproductor cuando empieza a sonar una cancion.
' =====================================================================
RequireLogin

Dim sid
sid = ToInt(Request.QueryString("id"))

If sid > 0 Then
  DbExec "UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS,0) + 1 WHERE ID_SONG = " & sid
End If

Response.ContentType = "application/json"
Response.CharSet = "utf-8"
Response.Write "{""ok"":true,""id"":" & sid & "}"
CloseDb
%>

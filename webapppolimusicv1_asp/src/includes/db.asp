<%
' =====================================================================
'  PoliMusic - Capa de acceso a datos (ADO sobre ODBC Driver 18)
'  Todos los valores que provienen del usuario se escapan con Q()/N()/DQ()
' =====================================================================

Const DB_DEBUG = True          ' True muestra el detalle del error SQL

Dim gConn
Set gConn = Nothing

' ------------------------- Conexion ----------------------------------
Function ConnString()
  ConnString = "Driver=" & DB_DRIVER & _
               ";Server=" & DB_SERVER & _
               ";Database=" & DB_CATALOG & _
               ";UID=" & DB_USER & _
               ";PWD=" & DB_PASSWORD & _
               ";Encrypt=yes;TrustServerCertificate=yes;"
End Function

Sub OpenDb()
  If Not (gConn Is Nothing) Then Exit Sub
  On Error Resume Next
  Set gConn = Server.CreateObject("ADODB.Connection")
  gConn.CommandTimeout = 30
  gConn.Open ConnString()
  If Err.Number <> 0 Then
    DbFail "No se pudo conectar a la base de datos BDD_PoliMusic.", Err.Description
  End If
  On Error GoTo 0
End Sub

Sub CloseDb()
  On Error Resume Next
  If Not (gConn Is Nothing) Then
    If gConn.State = 1 Then gConn.Close
  End If
  Set gConn = Nothing
  On Error GoTo 0
End Sub

' ------------------- Manejo de errores -------------------------------
Sub DbFail(titulo, detalle)
  Response.Write "<!DOCTYPE html><html lang='es'><head><meta charset='utf-8'>" & _
                 "<title>Error - " & H(APP_NAME) & "</title>" & _
                 "<style>body{font-family:Segoe UI,Arial,sans-serif;background:#140f0b;color:#f7f1e8;" & _
                 "padding:40px;line-height:1.5}h1{color:#c08552}code{background:#241b14;padding:2px 6px;" & _
                 "border-radius:4px;color:#dda36a}a{color:#dda36a}</style></head><body>" & _
                 "<h1>Se produjo un error</h1><p>" & H(titulo) & "</p>"
  If DB_DEBUG Then
    Response.Write "<p><strong>Detalle:</strong></p><pre><code>" & H(detalle) & "</code></pre>"
  End If
  Response.Write "<p><a href='" & Url("home.asp") & "'>Volver al inicio</a></p></body></html>"
  Response.End
End Sub

' ------------------- Consultas ---------------------------------------
' Devuelve un Recordset desconectado listo para recorrer
' Nota: en VBScript "On Error Resume Next" NO limpia el objeto Err, por eso
' se llama a Err.Clear antes de cada operacion. Sin esto, un error residual
' anterior se confundiria con un fallo de la consulta.
Function DbRs(sql)
  Dim rs, d
  On Error Resume Next
  Err.Clear
  Set rs = Server.CreateObject("ADODB.Recordset")
  rs.CursorLocation = 3                    ' adUseClient
  Err.Clear
  rs.Open sql, gConn, 3, 1                 ' adOpenStatic, adLockReadOnly
  If Err.Number <> 0 Then
    d = "[" & Err.Number & "] " & Err.Source & " - " & Err.Description
    On Error GoTo 0
    DbFail "Error al ejecutar la consulta.", d & vbCrLf & "SQL: " & sql
  End If
  On Error GoTo 0
  Set rs.ActiveConnection = Nothing
  Set DbRs = rs
End Function

' Ejecuta INSERT / UPDATE / DELETE y devuelve las filas afectadas
Function DbExec(sql)
  Dim n, d
  On Error Resume Next
  Err.Clear
  gConn.Execute sql, n, 1              ' Execute(CommandText, RecordsAffected, Options)
  If Err.Number <> 0 Then
    d = "[" & Err.Number & "] " & Err.Source & " - " & Err.Description
    On Error GoTo 0
    DbFail "Error al guardar los datos.", d & vbCrLf & "SQL: " & sql
  End If
  On Error GoTo 0
  DbExec = n
End Function

' Primera columna de la primera fila (o valor por defecto)
Function DbScalar(sql, defVal)
  Dim rs
  DbScalar = defVal
  Set rs = DbRs(sql)
  If Not rs.EOF Then
    If Not IsNull(rs(0)) Then DbScalar = rs(0)
  End If
  rs.Close
  Set rs = Nothing
End Function

' Ultimo IDENTITY generado en esta conexion/sesion
Function LastId()
  LastId = DbScalar("SELECT CAST(@@IDENTITY AS int)", 0)
End Function

' Total de filas de una consulta COUNT(*)
Function DbCount(sql)
  DbCount = ToInt(DbScalar(sql, 0))
End Function

' Devuelve True si la consulta trae al menos una fila
Function DbExists(sql)
  Dim rs
  Set rs = DbRs(sql)
  DbExists = Not rs.EOF
  rs.Close
  Set rs = Nothing
End Function

' Valor seguro de un campo ("" si es NULL)
Function F(rs, campo)
  If IsNull(rs(campo)) Then
    F = ""
  Else
    F = rs(campo)
  End If
End Function

Function FInt(rs, campo)
  FInt = ToInt(rs(campo))
End Function
%>

<%
' =====================================================================
'  PoliMusic - Subida de archivos (multipart/form-data)
'  Parser puro en VBScript.  El cuerpo de la peticion se convierte a una
'  cadena 1:1 con los bytes (charset iso-8859-1) para poder usar InStr/Mid
'  nativos, y se guarda con ADODB.Stream en modo binario.
' =====================================================================

' Los Dim globales deben ir ANTES de cualquier Class o Function:
' en VBScript, un Dim global despues de una definicion de procedimiento
' corrompe el ambito global y provoca "Name redefined" en la pagina.
Dim gUploads, gForm, gParsed, gEsMultipart

Class CUpload
  Public FieldName
  Public FileName
  Public ContentType
  Public Size
  Public RawContent
End Class

Set gUploads = Server.CreateObject("Scripting.Dictionary")
Set gForm    = Server.CreateObject("Scripting.Dictionary")
gParsed = False
gEsMultipart = False

' ------------------- conversion binario <-> texto --------------------
Function BytesToText(bytes)
  Dim st
  Set st = Server.CreateObject("ADODB.Stream")
  st.Type = 1
  st.Open
  st.Write bytes
  st.Position = 0
  st.Type = 2
  st.Charset = "iso-8859-1"
  BytesToText = st.ReadText
  st.Close
  Set st = Nothing
End Function

Sub TextToFile(txt, physPath)
  Dim st
  Set st = Server.CreateObject("ADODB.Stream")
  st.Type = 2
  st.Charset = "iso-8859-1"
  st.Open
  st.WriteText txt
  st.SaveToFile physPath, 2
  st.Close
  Set st = Nothing
End Sub

' ------------------------- parser ------------------------------------
Sub ParseUpload()
  Dim ct, bp, body, total, delim, p1, p2, part, hEnd, headerTxt, content

  If gParsed Then Exit Sub
  gParsed = True

  ct = CStr(Request.ServerVariables("CONTENT_TYPE") & "")
  If InStr(1, ct, "multipart/form-data", 1) = 0 Then Exit Sub
  gEsMultipart = True

  bp = InStr(1, ct, "boundary=", 1)
  If bp = 0 Then Exit Sub
  delim = Mid(ct, bp + 9)
  If InStr(delim, ";") > 0 Then delim = Left(delim, InStr(delim, ";") - 1)
  If Left(delim, 1) = """" Then delim = Mid(delim, 2, Len(delim) - 2)
  delim = Trim(delim)
  If Len(delim) = 0 Then Exit Sub

  total = Request.TotalBytes
  If total <= 0 Then Exit Sub

  On Error Resume Next
  body = BytesToText(Request.BinaryRead(total))
  If Err.Number <> 0 Then
    On Error GoTo 0
    Exit Sub
  End If
  On Error GoTo 0

  delim = "--" & delim
  p1 = InStr(1, body, delim, 1)
  Do While p1 > 0
    p2 = InStr(p1 + Len(delim), body, delim, 1)
    If p2 = 0 Then Exit Do
    part = Mid(body, p1 + Len(delim), p2 - (p1 + Len(delim)))
    If Left(part, 2) = vbCrLf Then part = Mid(part, 3)
    If Right(part, 2) = vbCrLf Then part = Left(part, Len(part) - 2)
    hEnd = InStr(1, part, vbCrLf & vbCrLf, 1)
    If hEnd > 0 Then
      headerTxt = Left(part, hEnd - 1)
      content   = Mid(part, hEnd + 4)
      ParsePart headerTxt, content
    End If
    p1 = p2
  Loop
End Sub

Sub ParsePart(headerTxt, content)
  Dim lines, i, line, nameVal, fileVal, ctVal, uf
  nameVal = ""
  fileVal = ""
  ctVal   = ""
  lines = Split(headerTxt, vbCrLf)
  For i = 0 To UBound(lines)
    line = lines(i)
    If LCase(Left(line, 19)) = "content-disposition" Then
      nameVal = HeaderParam(line, "name")
      fileVal = HeaderParam(line, "filename")
    ElseIf LCase(Left(line, 13)) = "content-type:" Then
      ctVal = Trim(Mid(line, 14))
    End If
  Next
  If Len(nameVal) = 0 Then Exit Sub
  If Len(fileVal) = 0 Then
    gForm(nameVal) = content
  Else
    Set uf = New CUpload
    uf.FieldName   = nameVal
    uf.FileName    = StripPath(fileVal)
    uf.ContentType = ctVal
    uf.Size        = Len(content)
    uf.RawContent  = content
    Set gUploads(nameVal) = uf
  End If
End Sub

Function HeaderParam(line, param)
  Dim p, s, e
  HeaderParam = ""
  p = InStr(1, line, param & "=", 1)
  If p = 0 Then Exit Function
  s = p + Len(param) + 1
  If Mid(line, s, 1) = """" Then
    e = InStr(s + 1, line, """", 1)
    If e > 0 Then HeaderParam = Mid(line, s + 1, e - s - 1)
  Else
    e = InStr(s, line, ";", 1)
    If e = 0 Then e = Len(line) + 1
    HeaderParam = Trim(Mid(line, s, e - s))
  End If
End Function

' --------------------- acceso a campos -------------------------------
' Valor de un campo del formulario (multipart o urlencoded).
'
' IMPORTANTE: despues de Request.BinaryRead, ASP prohibe usar la
' coleccion Request.Form ("Cannot use Request.Form collection after
' calling BinaryRead", error ASP 0207).  Por eso, cuando la peticion es
' multipart y el campo no aparece en el formulario se devuelve cadena
' vacia en lugar de consultar Request.Form.  Esto ocurre, por ejemplo,
' con las casillas de verificacion no marcadas, que el navegador no envia.
Function FormVal(nombre)
  ParseUpload
  If gForm.Exists(nombre) Then
    FormVal = gForm(nombre)
  ElseIf gEsMultipart Then
    FormVal = ""
  Else
    FormVal = CStr("" & Request.Form(nombre))
  End If
End Function

Function HasUpload(nombre)
  ParseUpload
  HasUpload = gUploads.Exists(nombre)
End Function

Function UploadName(nombre)
  ParseUpload
  If gUploads.Exists(nombre) Then UploadName = gUploads(nombre).FileName Else UploadName = ""
End Function

Function UploadSize(nombre)
  ParseUpload
  If gUploads.Exists(nombre) Then UploadSize = gUploads(nombre).Size Else UploadSize = 0
End Function

' --------------------- guardado --------------------------------------
Sub EnsureFolder(physPath)
  Dim fso
  On Error Resume Next
  Set fso = Server.CreateObject("Scripting.FileSystemObject")
  If Not fso.FolderExists(physPath) Then fso.CreateFolder physPath
  Set fso = Nothing
  On Error GoTo 0
End Sub

' ---------------------------------------------------------------------
'  Guarda el archivo subido en <folder> y devuelve la ruta relativa con
'  el prefijo "~/" (formato usado en la base de datos).
'  Devuelve "" si no hay archivo, si excede el tamano o la extension no
'  esta permitida.
' ---------------------------------------------------------------------
Function SaveUpload(nombre, folder, extPermitidas, maxBytes, prefijo)
  Dim uf, ext, base, fname, rel, physDir, physPath

  SaveUpload = ""
  ParseUpload
  If Not gUploads.Exists(nombre) Then Exit Function
  Set uf = gUploads(nombre)
  If uf.Size <= 0 Or Len(uf.FileName) = 0 Then Exit Function
  If maxBytes > 0 Then
    If uf.Size > maxBytes Then
      SaveUpload = ""
      Exit Function
    End If
  End If

  ext = LCase(FileExt(uf.FileName))
  If InStr(1, "," & LCase(extPermitidas) & ",", "," & ext & ",", 1) = 0 Then Exit Function

  base = Slug(FileBaseName(uf.FileName))
  If Len(prefijo) > 0 Then base = Slug(prefijo) & "_" & base
  fname = base & "_" & UniqueStamp() & "." & ext

  rel     = folder & "/" & fname
  physDir = Server.MapPath(Url(folder))
  EnsureFolder physDir
  physPath = Server.MapPath(Url(rel))

  On Error Resume Next
  TextToFile uf.RawContent, physPath
  If Err.Number <> 0 Then
    On Error GoTo 0
    SaveUpload = ""
    Exit Function
  End If
  On Error GoTo 0

  SaveUpload = "~/" & rel
End Function
%>

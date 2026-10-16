<%
' =====================================================================
'  PoliMusic - Utilidades generales
'  Codificacion, conversion, rutas, fechas, mensajes y SHA-1
' =====================================================================

Dim gAppRoot
Dim gByteCount
gAppRoot = ""

' ---------------------------------------------------------------------
'  Root virtual de la aplicacion.
'  Se detecta automaticamente desde IIS (APPL_MD_PATH), de modo que el
'  proyecto funciona tanto en la raiz del sitio como en la subcarpeta
'  exigida /webapppolimusicv1_asp.  Si la deteccion fallara se usa la
'  constante APP_BASE declarada en config.asp.
' ---------------------------------------------------------------------
Function AppRoot()
  Dim md, p, detectado
  If Len(gAppRoot) > 0 Then
    AppRoot = gAppRoot
    Exit Function
  End If

  detectado = ""
  md = CStr(Request.ServerVariables("APPL_MD_PATH") & "")
  If Len(md) > 0 Then
    p = InStrRev(md, "/ROOT")
    If p > 0 Then detectado = Mid(md, p + 5)
  End If

  ' Respaldo: si IIS no informa la ruta, se deduce de SCRIPT_NAME
  If Len(detectado) = 0 Then
    Dim sn
    sn = CStr(Request.ServerVariables("SCRIPT_NAME") & "")
    If InStr(1, sn, APP_BASE & "/", 1) = 1 Then detectado = APP_BASE
  End If

  ' Respaldo final: constante del proyecto
  If Len(detectado) = 0 Then detectado = APP_BASE

  gAppRoot = detectado
  AppRoot = gAppRoot
End Function

' URL absoluta (desde el root del sitio) de un recurso de la app
Function Url(relPath)
  Dim s
  s = Trim(CStr("" & relPath))
  s = Replace(s, "\", "/")
  Do While Left(s, 1) = "/"
    s = Mid(s, 2)
  Loop
  Url = AppRoot() & "/" & s
End Function

' ---------------------------------------------------------------------
'  URL para el atributo action de un formulario que se envia dentro del
'  iframe del shell.  Conserva ?f=1 para que la respuesta se renderice
'  dentro del marco y no se pierda el reproductor.
' ---------------------------------------------------------------------
Function FUrl(relPath)
  FUrl = Url(relPath) & "?f=1"
End Function

' ---------------------------------------------------------------------
'  Normaliza el nombre de carpeta que viene en la BD, ya que los datos
'  existentes usan mayusculas inconsistentes (~/songFiles, ~/userImages)
' ---------------------------------------------------------------------
Function CanonDir(name)
  Dim n
  n = LCase(Trim(CStr("" & name)))
  If n = "songfiles" Then
    CanonDir = DIR_SONG
  ElseIf n = "userimages" Then
    CanonDir = DIR_USER
  ElseIf n = "playlistimages" Then
    CanonDir = DIR_PLAYLIST
  ElseIf n = "albumimages" Then
    CanonDir = DIR_ALBUM
  ElseIf n = "artistimages" Then
    CanonDir = DIR_ARTIST
  Else
    CanonDir = CStr(name)
  End If
End Function

' Indica si existe el archivo fisico de un recurso relativo a la app
Function MediaExists(relPath)
  Dim fso
  MediaExists = False
  On Error Resume Next
  Set fso = Server.CreateObject("Scripting.FileSystemObject")
  MediaExists = fso.FileExists(Server.MapPath(Url(relPath)))
  Set fso = Nothing
  If Err.Number <> 0 Then MediaExists = False
  On Error GoTo 0
End Function

' ---------------------------------------------------------------------
'  Convierte una ruta guardada en BD (formato "~/carpeta/archivo") en
'  una URL utilizable.  Si el archivo no existe devuelve el default.
' ---------------------------------------------------------------------
Function ResolveMedia(storedPath, defaultRel)
  Dim p, slash, seg, rest, rel
  p = Trim(CStr("" & storedPath))
  If Len(p) = 0 Then
    ResolveMedia = DefaultUrl(defaultRel)
    Exit Function
  End If
  p = Replace(p, "\", "/")
  Do While Left(p, 2) = "~/"
    p = Mid(p, 3)
  Loop
  Do While Left(p, 1) = "/"
    p = Mid(p, 2)
  Loop
  slash = InStr(p, "/")
  If slash = 0 Then
    ResolveMedia = DefaultUrl(defaultRel)
    Exit Function
  End If
  seg  = Left(p, slash - 1)
  rest = Mid(p, slash + 1)
  rel  = CanonDir(seg) & "/" & rest
  If Not MediaExists(rel) Then
    ResolveMedia = DefaultUrl(defaultRel)
  Else
    ResolveMedia = Url(rel)
  End If
End Function

' Devuelve la URL del recurso por defecto ("" si no se especifica)
Function DefaultUrl(defaultRel)
  If Len(Trim(CStr("" & defaultRel))) = 0 Then
    DefaultUrl = ""
  Else
    DefaultUrl = Url(defaultRel)
  End If
End Function

' Accesos rapidos por tipo de recurso
Function ImgUser(p)
  ImgUser = ResolveMedia(p, IMG_USER_DEF)
End Function
Function ImgPlaylist(p)
  ImgPlaylist = ResolveMedia(p, IMG_PLAYLIST_DEF)
End Function
Function ImgAlbum(p)
  ImgAlbum = ResolveMedia(p, IMG_ALBUM_DEF)
End Function
Function ImgArtist(p)
  ImgArtist = ResolveMedia(p, IMG_ARTIST_DEF)
End Function

' URL de un archivo de audio guardado como "~/SongFiles/x.mp3"
Function SongUrl(storedPath)
  SongUrl = ResolveMedia(storedPath, "")
End Function

' ---------------------------------------------------------------------
'  Codificacion / conversion
' ---------------------------------------------------------------------
Function H(v)
  Dim s
  s = CStr("" & v)
  s = Replace(s, vbNullChar, "")
  s = Replace(s, "&", "&amp;")
  s = Replace(s, "<", "&lt;")
  s = Replace(s, ">", "&gt;")
  s = Replace(s, """", "&quot;")
  s = Replace(s, "'", "&#39;")
  H = s
End Function

' Igual que H() pero tolera valores nulos
Function HS(v)
  If IsNull(v) Or IsEmpty(v) Then
    HS = ""
  Else
    HS = H(v)
  End If
End Function

Function U(v)
  U = Server.URLEncode(CStr("" & v))
End Function

Function ToInt(v)
  Dim s
  ToInt = 0
  If IsNull(v) Or IsEmpty(v) Then Exit Function
  s = Trim(CStr(v))
  If Len(s) = 0 Then Exit Function
  If Not IsNumeric(s) Then Exit Function
  If CDbl(s) > 2147483647 Or CDbl(s) < -(2 ^ 31) Then Exit Function
  ToInt = CLng(s)
End Function

Function ToDbl(v, defVal)
  ToDbl = defVal
  If IsNull(v) Or IsEmpty(v) Then Exit Function
  If Len(Trim(CStr(v))) = 0 Then Exit Function
  If IsNumeric(v) Then ToDbl = CDbl(v)
End Function

' Escapa una cadena para usarla como literal SQL
Function Q(v)
  Dim s
  If IsNull(v) Or IsEmpty(v) Then
    Q = "NULL"
    Exit Function
  End If
  s = CStr(v)
  If Len(s) > 4000 Then s = Left(s, 4000)
  s = Replace(s, vbNullChar, "")
  s = Replace(s, "'", "''")
  Q = "'" & s & "'"
End Function

' Devuelve un numero o NULL
Function N(v)
  N = "NULL"
  If IsNull(v) Or IsEmpty(v) Then Exit Function
  If Len(Trim(CStr(v))) = 0 Then Exit Function
  If IsNumeric(v) Then N = CStr(CLng(v))
End Function

' Devuelve una fecha 'YYYY-MM-DD' o NULL
Function DQ(v)
  Dim s
  DQ = "NULL"
  If IsNull(v) Or IsEmpty(v) Then Exit Function
  s = Trim(CStr(v))
  If Len(s) = 0 Then Exit Function
  s = Replace(s, "'", "''")
  DQ = "'" & s & "'"
End Function

Function IsBlank(v)
  If IsNull(v) Or IsEmpty(v) Then
    IsBlank = True
  Else
    IsBlank = (Len(Trim(CStr(v))) = 0)
  End If
End Function

Function Trunc(s, maxLen)
  Dim t
  t = CStr("" & s)
  If Len(t) > maxLen Then t = Left(t, maxLen - 1) & Chr(8230)
  Trunc = t
End Function

' --------------------------- Fechas ----------------------------------
Function FormatDate(v)
  FormatDate = ""
  If IsNull(v) Or IsEmpty(v) Then Exit Function
  If Not IsDate(v) Then Exit Function
  FormatDate = Right("00" & Day(v), 2) & "/" & Right("00" & Month(v), 2) & "/" & Year(v)
End Function

Function FormatDateInput(v)
  FormatDateInput = ""
  If IsNull(v) Or IsEmpty(v) Then Exit Function
  If Not IsDate(v) Then Exit Function
  FormatDateInput = Right("0000" & Year(v), 4) & "-" & Right("00" & Month(v), 2) & "-" & Right("00" & Day(v), 2)
End Function

Function FormatDateTime(v)
  FormatDateTime = ""
  If IsNull(v) Or IsEmpty(v) Then Exit Function
  If Not IsDate(v) Then Exit Function
  FormatDateTime = FormatDate(v) & " " & Right("00" & Hour(v), 2) & ":" & Right("00" & Minute(v), 2)
End Function

Function Age(birthday)
  Age = ""
  If IsNull(birthday) Or IsEmpty(birthday) Then Exit Function
  If Not IsDate(birthday) Then Exit Function
  Age = DateDiff("yyyy", birthday, Date())
  If Month(birthday) > Month(Date()) Then Age = Age - 1
  If Month(birthday) = Month(Date()) And Day(birthday) > Day(Date()) Then Age = Age - 1
End Function

' ------------------- Nombres de archivo ------------------------------
Function StripPath(p)
  Dim s, i
  s = Replace(CStr("" & p), "\", "/")
  i = InStrRev(s, "/")
  If i > 0 Then s = Mid(s, i + 1)
  StripPath = s
End Function

Function FileExt(p)
  Dim s, i
  s = StripPath(p)
  i = InStrRev(s, ".")
  If i > 0 Then FileExt = Mid(s, i + 1) Else FileExt = ""
End Function

Function FileBaseName(p)
  Dim s, i
  s = StripPath(p)
  i = InStrRev(s, ".")
  If i > 1 Then FileBaseName = Left(s, i - 1) Else FileBaseName = s
End Function

' Convierte un texto en un nombre de archivo seguro
Function Slug(s)
  Dim i, ch, out, src
  src = LCase(Trim(CStr("" & s)))
  out = ""
  For i = 1 To Len(src)
    ch = Mid(src, i, 1)
    If (ch >= "a" And ch <= "z") Or (ch >= "0" And ch <= "9") Then
      out = out & ch
    ElseIf ch = " " Or ch = "-" Or ch = "_" Or ch = "." Then
      out = out & "_"
    End If
  Next
  Do While InStr(out, "__") > 0
    out = Replace(out, "__", "_")
  Loop
  If Len(out) = 0 Then out = "archivo"
  If Len(out) > 40 Then out = Left(out, 40)
  Slug = out
End Function

Function UniqueStamp()
  Dim d
  d = Now()
  UniqueStamp = Right("0000" & Year(d), 4) & Right("00" & Month(d), 2) & _
                Right("00" & Day(d), 2) & Right("00" & Hour(d), 2) & _
                Right("00" & Minute(d), 2) & Right("00" & Second(d), 2) & _
                CStr(Int(Rnd() * 9000) + 1000)
End Function

' ---------------------- Mensajes flash -------------------------------
' Uso:  SetFlash "Guardado correctamente", "ok"
Sub SetFlash(msg, tipo)
  Session("flash_msg")  = msg
  Session("flash_tipo") = tipo
End Sub

Function TakeFlashMsg()
  TakeFlashMsg = CStr("" & Session("flash_msg"))
  Session("flash_msg") = ""
End Function

Function TakeFlashTipo()
  TakeFlashTipo = CStr("" & Session("flash_tipo"))
  Session("flash_tipo") = ""
End Function

' ---------------------- JSON ----------------------------------------
' Escapa un valor para incrustarlo en JSON.  Ademas elimina cualquier
' caracter de control (incluido el byte nulo) porque romperia tanto el
' JSON como el atributo HTML que lo contiene.
Function Js(v)
  Dim s, i, c, ch, res
  s = CStr("" & v)
  s = Replace(s, "\", "\\")
  s = Replace(s, """", "\""")
  res = ""
  For i = 1 To Len(s)
    c  = Mid(s, i, 1)
    ch = AscW(c)
    If ch < 32 Then
      res = res & " "
    Else
      res = res & c
    End If
  Next
  Js = res
End Function

' =====================================================================
'  SHA-1 puro en VBScript  ->  cadena HEX en MAYUSCULAS (40 caracteres)
'  Coincide con HASHBYTES('SHA1', ...) de SQL Server para texto ASCII.
' =====================================================================


Function ToUtf8Bytes(s)
  Dim arr(), n, i, ch, b
  ReDim arr(Len(s) * 4 + 4)
  n = 0
  For i = 1 To Len(s)
    ch = AscW(Mid(s, i, 1))
    If ch < 0 Then ch = ch + 65536
    If ch < 128 Then
      arr(n) = ch
      n = n + 1
    ElseIf ch < 2048 Then
      arr(n) = 192 + Int(ch / 64) : n = n + 1
      arr(n) = 128 + (ch Mod 64) : n = n + 1
    Else
      arr(n) = 224 + Int(ch / 4096) : n = n + 1
      arr(n) = 128 + (Int(ch / 64) Mod 64) : n = n + 1
      arr(n) = 128 + (ch Mod 64) : n = n + 1
    End If
  Next
  If n = 0 Then
    ReDim arr(0)
    arr(0) = 0
    n = 0
  Else
    ReDim Preserve arr(n - 1)
  End If
  gByteCount = n
  ToUtf8Bytes = arr
End Function

Function Add32(x, y)
  Dim s
  s = CDbl(x) + CDbl(y)
  s = s - Int(s / (2 ^ 32)) * (2 ^ 32)
  If s >= (2 ^ 31) Then s = s - (2 ^ 32)
  Add32 = CLng(s)
End Function

' Rotacion circular a la izquierda de 32 bits.
'   resultado = ((x mod 2^(32-n)) << n) + (x >> (32-n))
' El segundo sumando es imprescindible: son los bits que "salen" por la
' izquierda y vuelven a entrar por la derecha.
Function RotL(x, n)
  Dim d, m, alto, bajo
  d = CDbl(x)
  If d < 0 Then d = d + (2 ^ 32)
  m = 2 ^ (32 - n)
  alto = Int(d / m)
  bajo = d - alto * m
  d = bajo * (2 ^ n) + alto
  If d >= (2 ^ 31) Then d = d - (2 ^ 32)
  RotL = CLng(d)
End Function

Function Hex32(v)
  Dim d, i, nib, s
  d = CDbl(v)
  If d < 0 Then d = d + (2 ^ 32)
  s = ""
  For i = 7 To 0 Step -1
    nib = Int(d / (16 ^ i)) - Int(d / (16 ^ (i + 1))) * 16
    s = s & Mid("0123456789ABCDEF", CLng(nib) + 1, 1)
  Next
  Hex32 = s
End Function

Function SHA1(texto)
  Dim src, msgLen, totalLen, pad(), i, blk, nBlk, w(79), t
  Dim h0, h1, h2, h3, h4, a, b, c, d, e, f, k, temp, bitLen, blkStart, byteIdx

  src    = CStr("" & texto)
  src    = ToUtf8Bytes(src)
  msgLen = gByteCount

  ' Longitud total del mensaje con padding: multiplo de 64
  totalLen = (Int((msgLen + 8) / 64) + 1) * 64
  ReDim pad(totalLen - 1)

  For i = 0 To msgLen - 1
    pad(i) = src(i)
  Next
  pad(msgLen) = 128                      ' 0x80
  For i = msgLen + 1 To totalLen - 9
    pad(i) = 0
  Next

  ' Longitud en bits (64 bits big-endian)
  bitLen = CDbl(msgLen) * 8
  For i = 0 To 7
    byteIdx = totalLen - 8 + i
    pad(byteIdx) = Int(bitLen / (256 ^ (7 - i))) - Int(bitLen / (256 ^ (8 - i))) * 256
  Next

  h0 = &H67452301
  h1 = &HEFCDAB89
  h2 = &H98BADCFE
  h3 = &H10325476
  h4 = &HC3D2E1F0

  nBlk = totalLen \ 64
  For blk = 0 To nBlk - 1
    blkStart = blk * 64
    For t = 0 To 15
      w(t) = Add32(Add32(Add32(CDbl(pad(blkStart + t * 4)) * 16777216, _
                              CDbl(pad(blkStart + t * 4 + 1)) * 65536), _
                        CDbl(pad(blkStart + t * 4 + 2)) * 256), _
                  CDbl(pad(blkStart + t * 4 + 3)))
    Next
    For t = 16 To 79
      w(t) = RotL(w(t - 3) Xor w(t - 8) Xor w(t - 14) Xor w(t - 16), 1)
    Next

    a = h0 : b = h1 : c = h2 : d = h3 : e = h4

    For t = 0 To 79
      If t < 20 Then
        f = (b And c) Or ((Not b) And d)
        k = &H5A827999
      ElseIf t < 40 Then
        f = b Xor c Xor d
        k = &H6ED9EBA1
      ElseIf t < 60 Then
        f = (b And c) Or (b And d) Or (c And d)
        k = &H8F1BBCDC
      Else
        f = b Xor c Xor d
        k = &HCA62C1D6
      End If
      temp = Add32(Add32(Add32(Add32(RotL(a, 5), f), e), k), w(t))
      e = d
      d = c
      c = RotL(b, 30)
      b = a
      a = temp
    Next

    h0 = Add32(h0, a)
    h1 = Add32(h1, b)
    h2 = Add32(h2, c)
    h3 = Add32(h3, d)
    h4 = Add32(h4, e)
  Next

  SHA1 = Hex32(h0) & Hex32(h1) & Hex32(h2) & Hex32(h3) & Hex32(h4)
End Function
%>

<%
' =====================================================================
'  PoliMusic - Autenticacion y control de acceso por roles
'    ROLE_ADMIN (1) : CRUD de usuarios, canciones, artistas, albumes y
'                     cualquier playlist.
'    ROLE_USER  (0) : reproduce musica y administra SOLO sus playlists.
' =====================================================================

Sub InitSession()
  Session.Timeout = SESSION_MINUTES
End Sub

' ------------------------- estado ------------------------------------
Function IsLoggedIn()
  IsLoggedIn = (Len(CStr("" & Session("uid"))) > 0)
End Function

Function UserId()
  UserId = ToInt(Session("uid"))
End Function

Function UserName()
  UserName = CStr("" & Session("uname"))
End Function

Function UserType()
  UserType = ToInt(Session("utype"))
End Function

Function UserPhoto()
  UserPhoto = CStr("" & Session("uphoto"))
End Function

Function UserEmail()
  UserEmail = CStr("" & Session("uemail"))
End Function

Function IsAdmin()
  IsAdmin = (IsLoggedIn() And UserType() = ROLE_ADMIN)
End Function

' Etiqueta legible del rol
Function RoleLabel(t)
  If ToInt(t) = ROLE_ADMIN Then RoleLabel = "Administrador" Else RoleLabel = "Usuario"
End Function

Function PlaylistTypeLabel(t)
  If ToInt(t) = PL_PRIVATE Then PlaylistTypeLabel = "Privada" Else PlaylistTypeLabel = "Publica"
End Function

' --------------------- guardas de acceso -----------------------------
Sub RequireLogin()
  If Not IsLoggedIn() Then
    Response.Redirect Url("login.asp") & "?next=" & U(CurrentUrl())
    Response.End
  End If
End Sub

Sub RequireAdmin()
  RequireLogin
  If Not IsAdmin() Then
    SetFlash "No tienes permisos de administrador para acceder a esa seccion.", "error"
    If LCase(CStr(Request.QueryString("f") & "")) = "1" Then
      Response.Redirect Url("home.asp") & "?f=1"
    Else
      Response.Redirect Url("home.asp")
    End If
    Response.End
  End If
End Sub

' URL actual con su cadena de consulta
Function CurrentUrl()
  Dim qs
  qs = CStr(Request.ServerVariables("QUERY_STRING") & "")
  CurrentUrl = CStr(Request.ServerVariables("SCRIPT_NAME") & "")
  If Len(qs) > 0 Then CurrentUrl = CurrentUrl & "?" & qs
End Function

' ------------------------ login / logout ------------------------------
Sub FillSession(rs)
  Session("uid")    = ToInt(rs("ID_USER"))
  Session("uname")  = CStr("" & rs("USERNAME"))
  Session("utype")  = ToInt(rs("USER_TYPE"))
  Session("uemail") = CStr("" & rs("EMAIL"))
  Session("uphoto") = CStr("" & rs("USER_PHOTO"))
End Sub

' Devuelve True si las credenciales son correctas y deja la sesion lista
Function DoLogin(usuario, clave)
  Dim rs, sql, hash
  DoLogin = False
  usuario = Trim(CStr("" & usuario))
  clave   = CStr("" & clave)
  If Len(usuario) = 0 Or Len(clave) = 0 Then Exit Function

  hash = SHA1(clave)
  sql = "SELECT ID_USER, USERNAME, EMAIL, USER_TYPE, USER_PHOTO " & _
        "FROM TBL_USER WHERE USERNAME = " & Q(usuario) & _
        " AND UPPER(PASSWORD) = " & Q(hash)

  Set rs = DbRs(sql)
  If Not rs.EOF Then
    FillSession rs
    DoLogin = True
  End If
  rs.Close
  Set rs = Nothing
End Function

Sub DoLogout()
  Session.Contents.RemoveAll()
  Session.Abandon()
End Sub

' --------------------- usuario actual (desde BD) ----------------------
Function LoadCurrentUser()
  Set LoadCurrentUser = DbRs("SELECT * FROM TBL_USER WHERE ID_USER = " & N(UserId()))
End Function

' ---------------------------------------------------------------------
'  Permisos sobre playlists: el administrador puede con todas, el
'  usuario normal solo con las suyas.
' ---------------------------------------------------------------------
Function PlaylistOwner(idPlaylist)
  PlaylistOwner = ToInt(DbScalar("SELECT ID_USER FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & ToInt(idPlaylist), 0))
End Function

Function CanManagePlaylist(idPlaylist)
  If Not IsLoggedIn() Then
    CanManagePlaylist = False
    Exit Function
  End If
  If IsAdmin() Then
    CanManagePlaylist = True
    Exit Function
  End If
  CanManagePlaylist = (PlaylistOwner(idPlaylist) = UserId())
End Function

' Una playlist privada solo la ve su duenio (o el administrador)
Function CanViewPlaylist(idPlaylist)
  Dim tipo, duenio
  tipo = ToInt(DbScalar("SELECT TYPE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & ToInt(idPlaylist), -1))
  If tipo < 0 Then
    CanViewPlaylist = False
    Exit Function
  End If
  If tipo = PL_PUBLIC Or IsAdmin() Then
    CanViewPlaylist = True
    Exit Function
  End If
  duenio = PlaylistOwner(idPlaylist)
  CanViewPlaylist = (duenio = UserId())
End Function
Function SafeRedirect(target, fallback)
  Dim t
  t = Trim(CStr("" & target))
  If Len(t) = 0 Then
    SafeRedirect = fallback
    Exit Function
  End If
  If Left(t, 2) = "//" Or Left(t, 3) = "\\" Then
    SafeRedirect = fallback
    Exit Function
  End If
  If InStr(t, ":") > 0 Then
    SafeRedirect = fallback
    Exit Function
  End If
  If Left(t, 1) <> "/" And InStr(t, "..") > 0 Then
    SafeRedirect = fallback
    Exit Function
  End If
  If Left(t, 1) = "/" Then
    SafeRedirect = t
  Else
    SafeRedirect = AppRoot() & "/" & t
  End If
End Function
%>

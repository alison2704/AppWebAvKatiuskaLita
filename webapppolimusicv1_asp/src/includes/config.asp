<% Option Explicit %>
<%
' =====================================================================
'  PoliMusic - Configuracion global
'  Tecnologia : ASP Clasico (VBScript) + ADO sobre ODBC Driver 18
'  Base datos : SQL Server - BDD_PoliMusic
' =====================================================================

' ------------------------- Identidad -------------------------
Const APP_NAME     = "PoliMusic"
Const APP_SUBTITLE = "Escuela Politecnica Nacional"
Const APP_VERSION  = "1.0"

' ------------------- Ruta base del proyecto ------------------
' REQUERIMIENTO ACADEMICO: la carpeta fisica, la aplicacion de IIS y
' la ruta base virtual del proyecto deben llamarse exactamente asi.
'   Carpeta      : C:\inetpub\wwwroot\webapppolimusicv1_asp
'   Aplicacion   : Default Web Site/webapppolimusicv1_asp
'   Ruta base    : /webapppolimusicv1_asp/
Const APP_FOLDER = "webapppolimusicv1_asp"
Const APP_BASE   = "/webapppolimusicv1_asp"

' ------------------------- Base de datos ---------------------
Const DB_DRIVER   = "{ODBC Driver 18 for SQL Server}"
Const DB_SERVER   = "localhost,14333"
Const DB_CATALOG  = "BDD_PoliMusic"
Const DB_USER     = "usr_polimusic"
Const DB_PASSWORD = "Politecnica1"

' ------------------------- Roles -----------------------------
' TBL_CATALOG -> COD_CATALOG_PARENT = '1'  (USER TYPE)
Const ROLE_USER  = 0
Const ROLE_ADMIN = 1

' --------------------- Tipo de playlist ----------------------
' TBL_CATALOG -> COD_CATALOG_PARENT = '2'  (PLAYLIST TYPE)
Const PL_PUBLIC  = 0
Const PL_PRIVATE = 1

' ------------- Carpetas de recursos (bajo el root web) -------
Const DIR_USER     = "UserImages"
Const DIR_PLAYLIST = "PlaylistImages"
Const DIR_ALBUM    = "AlbumImages"
Const DIR_ARTIST   = "ArtistImages"
Const DIR_SONG     = "SongFiles"

' ------------------- Imagenes por defecto ----------------------
' Nota: en VBScript una Const NO admite concatenacion con &,
' por eso las rutas se escriben como literales completos.
Const IMG_USER_DEF     = "UserImages/default.jpg"
Const IMG_PLAYLIST_DEF = "PlaylistImages/default.jpg"
Const IMG_ALBUM_DEF    = "AlbumImages/default.jpg"
Const IMG_ARTIST_DEF   = "ArtistImages/default.jpg"

' ------------------- Limites de subida ----------------------
Const UPLOAD_MAX_IMAGE = 5242880      ' 5 MB
Const UPLOAD_MAX_AUDIO = 31457280     ' 30 MB
Const EXT_IMAGE = "jpg,jpeg,png,gif,webp,bmp"
Const EXT_AUDIO = "mp3,wav,ogg,m4a,aac"

' --------------------------- Sesion -------------------------
Const SESSION_MINUTES = 60
%>

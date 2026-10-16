# webapppolimusicv1_asp

Clon de Spotify desarrollado en **ASP Clásico (VBScript)** sobre **IIS** y **SQL Server**,
con una paleta **marrón** en lugar del verde característico de Spotify.

**Versión:** 1.0
**Institución:** Escuela Politécnica Nacional
**URL de la aplicación:** `http://localhost/webapppolimusicv1_asp/`

---

## 1. Descripción

Aplicación web de streaming musical que permite explorar un catálogo de canciones,
álbumes y artistas, crear y administrar playlists, y reproducir audio con un
reproductor persistente. Cuenta con dos roles (administrador y usuario normal) y
un módulo completo de CRUD.

### Funcionalidades

| Módulo | Usuario normal | Administrador |
|---|---|---|
| Reproducir canciones, álbumes y artistas | Sí | Sí |
| Buscar en el catálogo | Sí | Sí |
| Ver playlists públicas | Sí | Sí |
| **Crear / editar / eliminar sus propias playlists** | **Sí** | Sí |
| Agregar y quitar canciones de sus playlists | Sí | Sí |
| Editar su propio perfil y contraseña | Sí | Sí |
| CRUD de canciones | No | Sí |
| CRUD de artistas | No | Sí |
| CRUD de álbumes y sus tracklists | No | Sí |
| CRUD de playlists de cualquier usuario | No | Sí |
| CRUD de usuarios y asignación de roles | No | Sí |

### Pantallas

- **Login** y **registro** (enrolamiento de usuarios con foto opcional)
- **Pantalla principal** con saludo, estadísticas, playlists, álbumes, artistas y más escuchadas
- **Búsqueda** unificada (canciones, álbumes, artistas)
- **Canciones**, **Álbumes**, **Artistas** con sus fichas de detalle
- **Playlists** con detalle y gestión de canciones
- **Usuarios** (solo administrador)
- **Mi perfil**

---

## 2. Tecnologías

| Componente | Detalle |
|---|---|
| Servidor web | IIS 10 (Windows) |
| Lenguaje servidor | ASP Clásico — VBScript 5.x |
| Acceso a datos | ADO sobre **ODBC Driver 18 for SQL Server** |
| Base de datos | SQL Server 2025 Express (`BDD_PoliMusic`) |
| Cliente | HTML5, CSS3 con variables, JavaScript sin dependencias |
| Reproductor | API `<audio>` de HTML5 |

No se utilizan librerías externas, frameworks ni componentes de terceros.

---

## 3. Requisitos previos

1. **Windows** con IIS instalado y la característica **ASP** habilitada.
2. **SQL Server** escuchando en `localhost,14333` con la base `BDD_PoliMusic`.
3. **ODBC Driver 18 for SQL Server** (o el 17).
4. **PowerShell 5.1** o superior.

---

## 4. Estructura del proyecto

```
webapppolimusicv1_asp/
├── src/                        <- Código fuente de la aplicación
│   ├── default.asp             <- Punto de entrada (redirige a login o al shell)
│   ├── index.asp               <- Shell: barra lateral + reproductor + iframe
│   ├── login.asp / logout.asp
│   ├── register.asp            <- Enrolamiento de usuarios
│   ├── home.asp                <- Pantalla principal
│   ├── search.asp
│   ├── songs.asp / song-form.asp
│   ├── artists.asp / artist-detail.asp / artist-form.asp
│   ├── albums.asp / album-detail.asp / album-form.asp
│   ├── playlists.asp / playlist-detail.asp / playlist-form.asp
│   ├── users.asp / user-form.asp        <- Solo administrador
│   ├── profile.asp
│   ├── api-play.asp            <- Incrementa el contador de reproducciones
│   ├── web.config
│   ├── css/style.css           <- Tema marrón completo
│   ├── js/app.js               <- Reproductor persistente y utilidades de UI
│   ├── includes/
│   │   ├── init.asp            <- Incluye todo lo anterior y abre la conexión
│   │   ├── config.asp          <- Constantes: BD, roles, rutas, límites
│   │   ├── db.asp              <- Capa ADO (DbRs, DbExec, DbScalar...)
│   │   ├── util.asp            <- SHA-1, escapado, rutas, fechas, JSON
│   │   ├── upload.asp          <- Parser multipart/form-data propio
│   │   ├── auth.asp            <- Sesión, roles y permisos
│   │   ├── widgets.asp         <- Consultas reutilizables y componentes
│   │   └── layout.asp          <- Cabeceras, menú, reproductor
│   ├── UserImages/  PlaylistImages/  AlbumImages/  ArtistImages/  SongFiles/
├── deploy.ps1                  <- Script de despliegue (requiere administrador)
├── desplegar.bat               <- Lanzador que se auto-eleva (UAC)
├── BDD_PoliMusic.sql           <- Script de creación de la base de datos
└── _tools/                     <- Utilidades de desarrollo (no se despliegan)
    ├── checkasp.js             <- Verificador de bloques VBScript
    └── generar_audios.py       <- Genera audios de relleno
```

---

## 5. Base de datos

Ejecutar `BDD_PoliMusic.sql` en SQL Server. El script crea:

- El login `usr_polimusic` y la base `BDD_PoliMusic`
- Las tablas: `TBL_USER`, `TBL_SONG`, `TBL_ALBUM`, `TBL_ARTIST`, `TBL_PLAYLIST`,
  `TBL_TRACKLIST`, `TBL_PLAYER`, `TBL_PLAYLIST_SONG`, `TBL_CATALOG`
- Las claves foráneas y los datos de ejemplo

### Cadena de conexión

```
Driver={ODBC Driver 18 for SQL Server};
Server=localhost,14333;Database=BDD_PoliMusic;
UID=usr_polimusic;PWD=Politecnica1;
Encrypt=yes;TrustServerCertificate=yes;
```

Se configura en `src/includes/config.asp`.

### Contraseñas

Se almacenan como **SHA-1 en hexadecimal mayúsculas** (40 caracteres).
La implementación de SHA-1 está escrita en VBScript puro (`includes/util.asp`) y
está verificada contra los valores de referencia:

| Entrada | SHA-1 |
|---|---|
| *(vacío)* | `DA39A3EE5E6B4B0D3255BFEF95601890AFD80709` |
| `abc` | `A9993E364706816ABA3E25717850C26C9CD0D89D` |
| `12345678` | `7C222FB2927D828AF22F592134E8932480637C0D` |

---

## 6. Despliegue

### Opción A — Automático (recomendado)

1. Doble clic en **`desplegar.bat`**.
2. Aceptar el aviso de **UAC**.

El script realiza automáticamente:

| Paso | Acción |
|---|---|
| 1 | Verifica privilegios de administrador |
| 2 | Detiene el App Pool si ya existe |
| 3 | Copia `src/` a `C:\inetpub\wwwroot\webapppolimusicv1_asp` |
| 4 | Crea el App Pool `webapppolimusicv1_asp` (64 bits, sin código administrado) |
| 5 | Registra la aplicación `Default Web Site/webapppolimusicv1_asp` |
| 6 | Retira el despliegue anterior si existía |
| 7 | Configura ASP: subida máx. 50 MB, errores detallados, sesiones de 60 min |
| 8 | Registra los tipos MIME `.webp` y `.m4a` |
| 9 | Otorga permisos: lectura a `IIS_IUSRS` y **escritura a `IUSR`** en las carpetas de medios |
| 10 | Inicia el App Pool y comprueba el sitio |

El detalle completo queda en `_tools/deploy.log`.

### Opción B — Manual

```powershell
# En una consola de PowerShell COMO ADMINISTRADOR
.\deploy.ps1 -Source ".\src" -LogFile ".\_tools\deploy.log"
```

Parámetros disponibles: `-AppName`, `-PoolName`, `-SiteName`, `-NoLimpiar`.

---

## 7. Uso

Abrir en el navegador: **http://localhost/webapppolimusicv1_asp/**

### Cuentas de prueba

| Rol | Usuario | Contraseña |
|---|---|---|
| Administrador | `userAdmin` | `12345678` |
| Usuario normal | `userNormal` | `12345678` |

También existen `username1` / `12345678`, `Katiuska.Lita` / `12345567891`
y `Christian Puchaicela` / `jhashjsaa`.

Desde el enlace **Regístrate** se pueden crear cuentas nuevas, que siempre
se crean con rol de **usuario normal**.

---

## 8. Notas de diseño

### Reproductor persistente

La aplicación usa un **shell** (`index.asp`) que contiene la barra lateral y el
reproductor, y carga el contenido en un **`<iframe>`**. Así la música no se corta
al navegar entre pantallas, igual que en Spotify.

Las páginas de contenido se sirven con el parámetro `?f=1`. Si se abren
directamente (por ejemplo, desde un enlace guardado), `EnsureFrame()` redirige
al shell para reconstruir la interfaz completa.

### Ruta base

`AppRoot()` (`includes/util.asp`) deduce la ruta base automáticamente desde IIS,
con dos niveles de respaldo:

1. `APPL_MD_PATH`
2. `SCRIPT_NAME`
3. La constante `APP_BASE` de `config.asp` (`/webapppolimusicv1_asp`)

Todo el código genera sus enlaces con `Url()` / `FUrl()`, por lo que **no hay
ninguna ruta absoluta escrita a mano** en las vistas, el CSS ni el JavaScript.

### Subida de archivos

El parser `multipart/form-data` está escrito desde cero en VBScript
(`includes/upload.asp`). Convierte el cuerpo de la petición a una cadena 1:1 con
los bytes (charset `iso-8859-1`) para poder usar `InStr`/`Mid` nativos, y guarda
con `ADODB.Stream` en modo binario.

Límites: **5 MB** para imágenes y **30 MB** para audio.
Extensiones aceptadas: `jpg, jpeg, png, gif, webp, bmp` y `mp3, wav, ogg, m4a, aac`.

### Roles

- `USER_TYPE = 0` → usuario normal
- `USER_TYPE = 1` → administrador

Los valores coinciden con la tabla `TBL_CATALOG` (grupos `USER TYPE` y `PLAYLIST TYPE`).

---

## 9. Solución de problemas

| Síntoma | Causa y solución |
|---|---|
| **Error 500 con `Expected literal constant`** | En VBScript una `Const` no admite concatenación con `&`. Usar literales completos. |
| **Error 500 con `Expected identifier`** | VBScript **no soporta** parámetros `Optional`. Usar funciones separadas con distinto número de argumentos. |
| **Error 500 con `Name redefined`** | Los nombres de función y de variable comparten espacio en VBScript. No usar `Dim s`, `Dim u`, `Dim h`, `Dim q`, `Dim f`, `Dim j` en una página que incluya `util.asp`. |
| **`Illegal assignment: 'X'`** | Al renombrar una función hay que actualizar también la asignación de retorno dentro de ella. |
| **`Cannot use Request.Form collection after calling BinaryRead`** | Tras `Request.BinaryRead` no se puede usar `Request.Form`. En formularios multipart usar siempre `FormVal()`. |
| **Los campos de un formulario multipart llegan vacíos** | No leer `Request.Form` antes de que corra el parser. Usar `FormVal()`. |
| **Error 3004 "Write to file failed" al subir** | **ASP Clásico ejecuta los scripts como `IUSR`**, no como la identidad del App Pool. Hay que dar permiso de escritura a `IUSR` en las carpetas de medios (`deploy.ps1` ya lo hace). |
| **Las canciones no se reproducen y el artista sale vacío** | `FOR XML PATH('')` con ODBC y cursor cliente de ADO devuelve bytes nulos. Usar `STRING_AGG(...)` con `CAST(... AS varchar(1000))`. |
| **No se puede escribir en `C:\inetpub\wwwroot`** | Requiere elevación. Ejecutar `desplegar.bat` como administrador. |
| **`deploy.ps1` no encuentra la carpeta `src`** | Ejecutarlo con `-Source "<ruta completa>\src"`. El `.bat` ya lo hace. |

---

## 10. Sobre los archivos de audio

`BDD_PoliMusic.sql` inserta 5 canciones cuyos archivos provienen de
[bensound.com](https://www.bensound.com) (música libre de regalías). En el
proyecto original solo se entregó **`bensound-adventure.mp3`**.

Para que las 5 canciones se puedan reproducir en la demostración, los otros 4
archivos se generaron como **melodías sintetizadas** con `_tools/generar_audios.py`
(muestras distintas entre sí). Son audios de relleno para probar el reproductor.

Para usar los archivos reales, basta con reemplazar en `src/SongFiles/`:

```
bensound-dreams.mp3
bensound-energy.mp3
bensound-scifi.mp3
bensound-tomorrow.mp3
```

No hace falta tocar la base de datos: los nombres coinciden con los que ya
referencia `TBL_SONG.SONG_PATH`.

---

## 11. Utilidades de desarrollo

```bash
# Verificar la estructura de bloques de todos los archivos VBScript
node _tools/checkasp.js src

# Regenerar los audios de relleno
python _tools/generar_audios.py src/SongFiles
```

---

## 12. Licencia y créditos

- Música de ejemplo: [Bensound](https://www.bensound.com) — licencia libre de regalías.
- Imágenes: incluidas en el proyecto con fines académicos.

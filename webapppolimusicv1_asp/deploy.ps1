<#
=====================================================================
 Proyecto: webapppolimusicv1_asp
 Despliegue en IIS
 ---------------------------------------------------------------------
 Copia la aplicacion ASP Clasico a
      C:\inetpub\wwwroot\webapppolimusicv1_asp
 crea el App Pool, registra la aplicacion en IIS como
      Default Web Site/webapppolimusicv1_asp
 y ajusta los permisos necesarios.

 URL final: http://localhost/webapppolimusicv1_asp/

 REQUIERE EJECUTARSE COMO ADMINISTRADOR.
=====================================================================
#>

[CmdletBinding()]
param(
    [string]$Source    = "",
    [string]$SiteName  = "Default Web Site",
    [string]$AppName   = "webapppolimusicv1_asp",
    [string]$PoolName  = "webapppolimusicv1_asp",
    [string]$OldAppName  = "PoliMusic",
    [string]$OldPoolName = "PoliMusicAppPool",
    [switch]$NoLimpiar,
    [string]$LogFile   = ""
)

$ErrorActionPreference = "Continue"
$script:Errores = 0

# ---------------------------------------------------------------------
#  Resolucion robusta de la carpeta del script.
#  $PSScriptRoot puede llegar vacio en procesos elevados, asi que se
#  usan varias alternativas antes de rendirse.
# ---------------------------------------------------------------------
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    try { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition } catch { }
}
if ([string]::IsNullOrEmpty($ScriptDir)) {
    try { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path } catch { }
}
if ([string]::IsNullOrEmpty($ScriptDir)) { $ScriptDir = (Get-Location).Path }
if ([string]::IsNullOrEmpty($ScriptDir)) { $ScriptDir = "C:\Users\katy_\git\AppWebAvKatiuskaLita\webapppolimusicv1_asp" }

if ([string]::IsNullOrEmpty($Source))  { $Source  = Join-Path $ScriptDir "src" }
if ([string]::IsNullOrEmpty($LogFile)) { $LogFile = Join-Path $ScriptDir "_tools\deploy.log" }

function Log {
    param([string]$Msg, [string]$Nivel = "INFO")
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Nivel, $Msg
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Run {
    param([string]$Desc, [scriptblock]$Cmd)
    try {
        $out = & $Cmd 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            Log "$Desc -> codigo $LASTEXITCODE : $($out.Trim())" "WARN"
        } else {
            Log "$Desc -> OK $($out.Trim())"
        }
    } catch {
        Log "$Desc -> ERROR: $($_.Exception.Message)" "ERROR"
    }
}

# ---------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null
Set-Content -Path $LogFile -Value "=== Despliegue webapppolimusicv1_asp $(Get-Date) ===" -Encoding UTF8

Log "Iniciando despliegue de webapppolimusicv1_asp"
Log "Origen  : $Source"
Log "Destino : C:\inetpub\wwwroot\$AppName"
Log "App IIS : $SiteName/$AppName"
Log "App Pool: $PoolName"
Log "URL     : http://localhost/$AppName/"

# ------------------------- 1. Verificar privilegios -------------------
$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log "Ejecutando como administrador: $esAdmin"
if (-not $esAdmin) {
    Log "Se requieren privilegios de administrador. Abortando." "ERROR"
    exit 1
}

if (-not (Test-Path $Source)) {
    Log "No existe la carpeta de origen indicada: $Source" "WARN"
    $candidatos = @(
        (Join-Path $ScriptDir "src"),
        "C:\Users\katy_\git\AppWebAvKatiuskaLita\webapppolimusicv1_asp\src",
        (Join-Path (Get-Location).Path "src")
    )
    $encontrado = $null
    foreach ($c in $candidatos) {
        if ((Test-Path $c) -and (Test-Path (Join-Path $c "default.asp"))) { $encontrado = $c; break }
    }
    if ($null -eq $encontrado) {
        Log "No se pudo localizar la carpeta 'src' de la aplicacion. Rutas probadas: $($candidatos -join ' | ')" "ERROR"
        Log "Ejecuta: deploy.ps1 -Source ""<ruta completa>\src"" -LogFile ""<ruta completa>\_tools\deploy.log""" "ERROR"
        exit 1
    }
    $Source = $encontrado
    Log "Carpeta de origen localizada automaticamente: $Source"
}
Log "Carpeta de origen validada: $Source"

$Destino = "C:\inetpub\wwwroot\$AppName"
$AppCmd  = "$env:windir\System32\inetsrv\appcmd.exe"

# ------------------------- 2. Detener el pool -------------------------
if (Test-Path $AppCmd) {
    Run "Detener app pool $PoolName" { & $AppCmd stop apppool /apppool.name:$PoolName }
}

# ------------------------- 3. Copiar archivos -------------------------
try {
    if (-not (Test-Path $Destino)) {
        New-Item -ItemType Directory -Force -Path $Destino | Out-Null
        Log "Carpeta destino creada: $Destino"
    }

    # /MIR mantiene el destino identico al origen (excluye los .log)
    $robolog = & robocopy $Source $Destino /MIR /NFL /NDL /NJH /NJS /XF *.log 2>&1 | Out-String
    $rc = $LASTEXITCODE
    if ($rc -lt 8) { Log "Copia de archivos completada (robocopy rc=$rc)" }
    else { Log "Robocopy reporto problemas (rc=$rc): $robolog" "WARN" }
} catch {
    Log "Error al copiar archivos: $($_.Exception.Message)" "ERROR"
}

# ------------------------- 4. Habilitar ASP ---------------------------
if (-not (Test-Path "$env:windir\System32\inetsrv\asp.dll")) {
    Log "asp.dll no encontrado. Habilitando caracteristica IIS-ASP..." "WARN"
    Run "Habilitar IIS-ASP" { Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP -All -NoRestart }
} else {
    Log "ASP Clasico disponible (asp.dll presente)"
}

# ------------------------- 5. App Pool --------------------------------
$poolExiste = (& $AppCmd list apppool /name:$PoolName 2>&1 | Out-String)
if (($poolExiste -notmatch 'ERROR') -and ($poolExiste -match 'APPPOOL "')) {
    Log "El app pool $PoolName ya existe"
} else {
    Run "Crear app pool $PoolName" {
        & $AppCmd add apppool /name:$PoolName /managedRuntimeVersion:"" /managedPipelineMode:Integrated
    }
}
Run "Configurar app pool (32 bits desactivado)" { & $AppCmd set apppool /apppool.name:$PoolName /enable32BitAppOnWin64:false }
Run "Configurar app pool (identidad ApplicationPoolIdentity)" { & $AppCmd set apppool /apppool.name:$PoolName /processModel.identityType:ApplicationPoolIdentity }
Run "Configurar app pool (inicio automatico)" { & $AppCmd set apppool /apppool.name:$PoolName /autoStart:true }

# ------------------------- 6. Aplicacion IIS --------------------------
$appExiste = (& $AppCmd list app "$SiteName/$AppName" 2>&1 | Out-String)
if (($appExiste -notmatch 'ERROR') -and ($appExiste -match 'APP "')) {
    Run "Eliminar aplicacion existente" { & $AppCmd delete app "$SiteName/$AppName" }
}
Run "Crear aplicacion $AppName" {
    & $AppCmd add app /site.name:"$SiteName" /path:"/$AppName" /physicalPath:"$Destino"
}
Run "Asignar app pool a la aplicacion" {
    & $AppCmd set app "$SiteName/$AppName" /applicationPool:$PoolName
}

# ------------- 6b. Limpieza del despliegue anterior -------------------
#  El despliegue previo se llamaba "PoliMusic".  Se retira para que el
#  proyecto quede unicamente como /webapppolimusicv1_asp/.
#  Usa  -NoLimpiar  si prefieres conservarlo.
if (-not $NoLimpiar) {
    $viejaApp = (& $AppCmd list app "$SiteName/$OldAppName" 2>&1 | Out-String)
    if (($viejaApp -notmatch 'ERROR') -and ($viejaApp -match 'APP "')) {
        Run "Retirar aplicacion anterior '$OldAppName'" { & $AppCmd delete app "$SiteName/$OldAppName" }
    }
    $viejoPool = (& $AppCmd list apppool /name:$OldPoolName 2>&1 | Out-String)
    if (($viejoPool -notmatch 'ERROR') -and ($viejoPool -match 'APPPOOL "')) {
        Run "Detener app pool anterior '$OldPoolName'" { & $AppCmd stop apppool /apppool.name:$OldPoolName }
        Run "Retirar app pool anterior '$OldPoolName'" { & $AppCmd delete apppool /apppool.name:$OldPoolName }
    }
    $carpetaVieja = "C:\inetpub\wwwroot\$OldAppName"
    if (Test-Path (Join-Path $carpetaVieja "includes\config.asp")) {
        try {
            Remove-Item -LiteralPath $carpetaVieja -Recurse -Force -ErrorAction Stop
            Log "Carpeta del despliegue anterior eliminada: $carpetaVieja"
        } catch {
            Log "No se pudo eliminar $carpetaVieja : $($_.Exception.Message)" "WARN"
        }
    } elseif (Test-Path $carpetaVieja) {
        Log "La carpeta $carpetaVieja no contiene el marcador del proyecto; no se elimina." "WARN"
    }
}

# ------------------------- 7. Limites de ASP --------------------------
Run "ASP: maxRequestEntityAllowed = 50 MB" {
    & $AppCmd set config /section:asp /limits.maxRequestEntityAllowed:52428800 /commit:apphost
}
Run "ASP: errores detallados en el navegador" {
    & $AppCmd set config /section:asp /scriptErrorSentToBrowser:true /commit:apphost
}
Run "ASP: sesiones habilitadas (60 min)" {
    & $AppCmd set config /section:asp /session.allowSessionState:true /session.timeout:01:00:00 /commit:apphost
}
Run "RequestFiltering: maxAllowedContentLength = 50 MB" {
    & $AppCmd set config /section:requestFiltering /requestLimits.maxAllowedContentLength:52428800 /commit:apphost
}

# ------------------------- 8. Tipos MIME ------------------------------
Run "MIME: .webp" { & $AppCmd set config /section:staticContent "/+[fileExtension='.webp',mimeType='image/webp']" /commit:apphost }
Run "MIME: .m4a (quitar si existia)" { & $AppCmd set config /section:staticContent "/-[fileExtension='.m4a']" /commit:apphost }
Run "MIME: .m4a"  { & $AppCmd set config /section:staticContent "/+[fileExtension='.m4a',mimeType='audio/mp4']" /commit:apphost }

# ------------------------- 8b. Permisos de edicion --------------------
#  Permite al usuario que ejecuta el despliegue editar los archivos ya
#  publicados (util para desarrollo).  Si no lo quieres, elimina esta
#  entrada con:  icacls <ruta> /remove "<usuario>" /T
$identidadUsuario = [Security.Principal.WindowsIdentity]::GetCurrent().Name
Run "Permisos de edicion para $identidadUsuario" {
    & icacls $Destino /grant "${identidadUsuario}:(OI)(CI)(M)" /T /Q
}

# ------------------------- 9. Permisos --------------------------------
Run "Permisos de lectura para IIS_IUSRS" {
    & icacls $Destino /grant "IIS_IUSRS:(OI)(CI)(RX)" /T /Q
}

# IMPORTANTE: ASP Clasico ejecuta los scripts con la identidad de la
# autenticacion anonima, que por defecto es IUSR (NO la identidad del
# App Pool).  Si solo se concede permiso al App Pool, las subidas de
# archivos fallan con "Write to file failed" (error 3004).
# Por eso se conceden permisos de escritura a las tres identidades.
$identidad = "IIS AppPool\$PoolName"
foreach ($carpeta in @("UserImages", "PlaylistImages", "AlbumImages", "ArtistImages", "SongFiles")) {
    $ruta = Join-Path $Destino $carpeta
    if (Test-Path $ruta) {
        Run "Escritura en $carpeta (App Pool)" {
            & icacls $ruta /grant "${identidad}:(OI)(CI)(M)" /T /Q
        }
        Run "Escritura en $carpeta (IUSR - identidad real de ASP)" {
            & icacls $ruta /grant "IUSR:(OI)(CI)(M)" /T /Q
        }
        Run "Escritura en $carpeta (IIS_IUSRS)" {
            & icacls $ruta /grant "IIS_IUSRS:(OI)(CI)(M)" /T /Q
        }
    } else {
        Log "Carpeta no encontrada: $ruta" "WARN"
    }
}

# ------------------------- 10. Iniciar el pool ------------------------
Run "Iniciar app pool $PoolName" { & $AppCmd start apppool /apppool.name:$PoolName }

$estado = (& $AppCmd list apppool /name:$PoolName 2>&1 | Out-String)
Log "Estado del app pool: $($estado.Trim())"

# ------------------------- 11. Comprobar el sitio ---------------------
$sitio = (& $AppCmd list site /name:"$SiteName" 2>&1 | Out-String)
if ($sitio -match "state:Started") { Log "El sitio '$SiteName' esta iniciado" }
else {
    Log "El sitio '$SiteName' no esta iniciado, iniciandolo..." "WARN"
    Run "Iniciar sitio $SiteName" { & $AppCmd start site /site.name:"$SiteName" }
}

$bindings = (& $AppCmd list site /name:"$SiteName" /text:bindings 2>&1 | Out-String).Trim()
Log "Bindings: $bindings"

Log "===================================================="
Log "URL de la aplicacion: http://localhost/$AppName/"
Log "Despliegue finalizado"
Log "===================================================="

exit 0

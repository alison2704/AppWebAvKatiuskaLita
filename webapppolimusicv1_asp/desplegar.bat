@echo off
setlocal EnableExtensions
title webapppolimusicv1_asp - Despliegue en IIS
cd /d "%~dp0"

set "APPNAME=webapppolimusicv1_asp"
set "DESTINO=C:\inetpub\wwwroot\webapppolimusicv1_asp"

if not exist "%~dp0_tools" mkdir "%~dp0_tools" >nul 2>&1

net session >nul 2>&1
if not errorlevel 1 goto :elevado

set "MARK=%~dp0_tools\bat_ran.txt"
echo === webapppolimusicv1_asp desplegar.bat (sin privilegios) === > "%MARK%"
echo Inicio : %DATE% %TIME% >> "%MARK%"
echo Usuario: %USERNAME% >> "%MARK%"
echo Elevacion requerida: solicitando UAC >> "%MARK%"
goto :elevar

:elevado
set "MARK=%~dp0_tools\bat_elevado.txt"
echo === webapppolimusicv1_asp desplegar.bat (ejecucion elevada) === > "%MARK%"
echo Inicio : %DATE% %TIME% >> "%MARK%"
echo Carpeta: %~dp0 >> "%MARK%"
echo Usuario: %USERNAME% >> "%MARK%"
echo Modo administrador: confirmado >> "%MARK%"
goto :ejecutar

:elevar
echo Elevacion requerida: solicitando UAC >> "%MARK%"
echo.
echo ================================================================
echo  Proyecto %APPNAME%
echo  Despliegue en IIS
echo ----------------------------------------------------------------
echo  Se necesitan permisos de administrador para publicar en IIS.
echo  Acepta el aviso de UAC que aparecera a continuacion.
echo  Si cancelas el aviso, no se desplegara nada.
echo ================================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >> "%MARK%" 2>&1
echo Resultado de Start-Process (0 = se lanzo el proceso elevado): %errorlevel% >> "%MARK%"
if errorlevel 1 (
    echo.
    echo  No se pudo solicitar la elevacion automaticamente.
    echo  Abre una consola de PowerShell COMO ADMINISTRADOR y ejecuta:
    echo.
    echo      powershell -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Source "%~dp0src" -LogFile "%~dp0_tools\deploy.log"
    echo.
    pause
)
exit /b

:ejecutar
echo.
echo ================================================================
echo  Proyecto : %APPNAME%
echo  Despliegue en IIS
echo ----------------------------------------------------------------
echo  Origen   : %~dp0src
echo  Destino  : %DESTINO%
echo  App IIS  : Default Web Site/%APPNAME%
echo  URL      : http://localhost/%APPNAME%/
echo ================================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Source "%~dp0src" -LogFile "%~dp0_tools\deploy.log"
set "RC=%errorlevel%"
echo.
echo ----------------------------------------------------------------
echo  Codigo de salida : %RC%
echo  Log detallado    : _tools\deploy.log
echo  URL esperada     : http://localhost/%APPNAME%/
echo ----------------------------------------------------------------
echo Codigo de salida: %RC% >> "%MARK%"
echo Fin: %DATE% %TIME% >> "%MARK%"
echo.
echo Presiona una tecla para cerrar esta ventana...
pause >nul
endlocal

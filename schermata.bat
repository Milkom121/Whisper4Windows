@echo off
chcp 65001 >nul
setlocal

rem ============================================================================
rem  Metodo Villa - la schermata del runner.
rem
rem  Il file che si apre col doppio clic: accende il servitore (se non gira
rem  gia') e apre il browser sulla schermata. Qui non c'e' logica: sta tutta in
rem  metodo/servitore-gui.py, come il resto della macchina. Questo file cerca
rem  solo Python e, se non lo trova, lo dice invece di chiudersi in silenzio.
rem ============================================================================

rem Quale Python usare: prima il lanciatore "py" (con la versione 3), poi
rem "python" nel PATH. La prova "-c print" scarta il finto python del Microsoft
rem Store: non e' installato, ma risponde lo stesso quando lo si chiama.
set "PY="
py -3 -c "print(1)" >nul 2>&1
if not errorlevel 1 set "PY=py -3"
if not defined PY (
    python -c "print(1)" >nul 2>&1
    if not errorlevel 1 set "PY=python"
)

if not defined PY (
    echo.
    echo    Non ho trovato Python: senza non si apre la schermata del runner.
    echo    Installalo da https://www.python.org/downloads/ e riprova.
    echo.
    pause
    exit /b 1
)

%PY% "%~dp0metodo\servitore-gui.py" apri %*
set "ESITO=%ERRORLEVEL%"
if not "%ESITO%"=="0" (
    echo.
    pause
)
exit /b %ESITO%

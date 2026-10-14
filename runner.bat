@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

rem ============================================================================
rem  Metodo Villa - unico punto di ingresso del progetto.
rem
rem  Sostituisce gli 8 avviatori precedenti (avvia-runner-*, aggiorna-metodo.*,
rem  rimanda-al-metodo.*), che erano due comandi riscritti quattro volte: due
rem  modalita' del runner x due formati .bat/.ps1 che duplicavano la stessa
rem  logica in due linguaggi.
rem
rem  Questo file sta nella RADICE del progetto perche' e' l'unica cosa del
rem  Metodo che l'umano tocca a mano; tutto il resto della macchina vive in
rem  metodo/ e in .claude/.
rem
rem  I motori restano dove sono: metodo/metodo-villa-runner.sh (esecuzione dei
rem  blocchi) e metodo/metodo-sync.sh (allineamento col Metodo ufficiale). Da
rem  riga di comando si lanciano ancora direttamente, questo file non li
rem  sostituisce.
rem ============================================================================

rem Radice del progetto = cartella di questo file, in formato che bash capisce.
set "ROOT_WIN=%~dp0"
set "ROOT=!ROOT_WIN:\=/!"
for %%I in ("%~dp0.") do set "PROJ=%%~nxI"
title %PROJ% - Metodo Villa

rem Serve bash: prima Git for Windows, in alternativa WSL. Si cerca UNA volta sola qui,
rem perche' serve sia ai comandi normali sia all'apertura delle finestre delle corsie.
set "GITBASH="
if exist "C:\Program Files\Git\bin\bash.exe" set "GITBASH=C:\Program Files\Git\bin\bash.exe"
if exist "C:\Program Files (x86)\Git\bin\bash.exe" set "GITBASH=C:\Program Files (x86)\Git\bin\bash.exe"

rem Dove metodo-corsie.sh apre i tavoli di lavoro: cartella sorella del progetto.
set "CORSIE_WIN=%~dp0..\%PROJ%-corsie"

rem Chi esegue i blocchi. Vuoto = quello che il progetto ha gia' scelto in .env.runner
rem (di norma Claude Code): chi non tocca niente non si accorge di nulla. La voce 11 del
rem menu permette di cambiarlo per QUESTA corsa, senza modificare la configurazione.
set "OPZ_AGENTE="
set "OPZ_MODELLO="
set "CHI_LAVORA=quello del progetto (di solito Claude Code)"
set "OPZ_OTTIMIZZA="
set "INSTRADAMENTO=spento (un solo motore per tutta la corsa)"

:menu
echo.
echo ========================================================
echo    METODO VILLA
echo    Progetto: %PROJ%
echo ========================================================
echo.
echo    COSTRUIRE
echo      1. Avvia il runner - si ferma a fine fase   (normale)
echo      2. Avvia il runner - tutte le fasi di fila
echo     11. Scegli chi lavora: !CHI_LAVORA!
echo     12. Un motore per ogni blocco: !INSTRADAMENTO!
echo.
echo    COSTRUIRE IN PARALLELO (piu' agenti insieme - vedi cap. 21)
echo      3. Chiedi il Consiglio degli Agenti - conviene dividere questa fase?
echo      4. Apri le corsie della fase
echo      5. Avvia tutte le corsie insieme
echo      6. A che punto sono le corsie
echo      7. Rimetti insieme il lavoro delle corsie
echo      8. Chiudi le corsie (il lavoro resta salvato)
echo.
echo    METODO
echo      9. Aggiorna il Metodo dalla fonte ufficiale
echo     10. Proponi una miglioria al Metodo (anteprima)
echo.
echo      0. Esci
echo.
set "SCELTA="
set /p "SCELTA=Che cosa vuoi fare? [1] "
if not defined SCELTA set "SCELTA=1"

if "%SCELTA%"=="1" goto runner_fase
if "%SCELTA%"=="2" goto runner_tutte
if "%SCELTA%"=="3" goto corsie_consiglio
if "%SCELTA%"=="4" goto corsie_prepara
if "%SCELTA%"=="5" goto corsie_avvia
if "%SCELTA%"=="6" goto corsie_stato
if "%SCELTA%"=="7" goto corsie_riunisci
if "%SCELTA%"=="8" goto corsie_smonta
if "%SCELTA%"=="9" goto aggiorna
if "%SCELTA%"=="10" goto rimanda
if "%SCELTA%"=="11" goto scegli_chi_lavora
if "%SCELTA%"=="12" goto scegli_instradamento
if "%SCELTA%"=="0" goto fine
echo.
echo    Scelta non valida: digita un numero da 0 a 12.
goto menu

:runner_fase
set "DESC=Runner - si ferma a fine fase"
set "CMD=chmod +x metodo/metodo-villa-runner.sh && ./metodo/metodo-villa-runner.sh --timeout 60 --verbose!OPZ_AGENTE!!OPZ_MODELLO!!OPZ_OTTIMIZZA!"
goto esegui

:runner_tutte
set "DESC=Runner - tutte le fasi di fila (si ferma solo a checkpoint, errore o blocco umano)"
set "CMD=chmod +x metodo/metodo-villa-runner.sh && ./metodo/metodo-villa-runner.sh --timeout 60 --verbose --tutte-le-fasi!OPZ_AGENTE!!OPZ_MODELLO!!OPZ_OTTIMIZZA!"
goto esegui

rem ---------------------------------------------------------------------------
rem  Un motore per ogni blocco: il peso scritto in roadmap decide chi lavora.
rem  Spento, la corsa usa un solo motore per tutti i blocchi (com'e' sempre stato).
rem ---------------------------------------------------------------------------
:scegli_instradamento
cls
echo.
echo    UN MOTORE PER OGNI BLOCCO
echo.
echo    Acceso, ogni blocco va al motore che gli tocca, secondo il peso
echo    scritto nella roadmap:
echo.
echo       cruciale    architettura, dati, sicurezza       -^> Claude Opus 5
echo       importante  schermate nuove, testi per l^utente  -^> Kimi K3
echo       ordinario   codice di routine, test, documenti   -^> GLM 5.3
echo.
echo    I blocchi senza peso scritto restano al motore della corsa.
echo    Se scegli il modello a mano (voce 11), l^instradamento si spegne.
echo.
echo      1. Spento   (un solo motore per tutta la corsa)
echo      2. Acceso   (un motore per ogni blocco)
echo.
set /p "INS=Che cosa faccio? [1] "
if "!INS!"=="" set "INS=1"
if "!INS!"=="2" (
    set "OPZ_OTTIMIZZA= --ottimizza"
    set "INSTRADAMENTO=acceso (un motore per ogni blocco)"
) else (
    set "OPZ_OTTIMIZZA="
    set "INSTRADAMENTO=spento (un solo motore per tutta la corsa)"
)
goto menu

rem ---------------------------------------------------------------------------
rem  Chi esegue i blocchi di QUESTA corsa. Con OpenCode va scelto anche il
rem  modello: si mostrano soltanto quelli utilizzabili davvero su questa
rem  macchina (i gratuiti, piu' quelli dei fornitori per cui esiste una chiave
rem  registrata in OpenCode). Sceglierne uno senza chiave vorrebbe dire lanciare
rem  una corsa che muore al primo blocco.
rem ---------------------------------------------------------------------------
:scegli_chi_lavora
echo.
echo    CHI ESEGUE I BLOCCHI
echo      1. Claude Code           (il predefinito del Metodo)
echo      2. OpenCode              (serve scegliere anche il modello)
echo      3. Lascia decidere al progetto (quello scritto in .env.runner)
echo.
set "MOT="
set /p "MOT=Con che cosa lancio? [1] "
if not defined MOT set "MOT=1"
if "%MOT%"=="3" (
    set "OPZ_AGENTE="
    set "OPZ_MODELLO="
    set "CHI_LAVORA=quello del progetto (di solito Claude Code)"
    goto menu
)
if "%MOT%"=="1" (
    set "OPZ_AGENTE= --agente claude"
    set "OPZ_MODELLO="
    set "CHI_LAVORA=Claude Code"
    goto menu
)
if not "%MOT%"=="2" (
    echo    Scelta non valida.
    goto menu
)
if not defined GITBASH (
    echo    Serve Git Bash per leggere l'elenco dei modelli.
    pause
    goto menu
)
set "ELENCO=%TEMP%\metodo-fornitori.txt"
"%GITBASH%" -lc "cd '%ROOT%' && ./metodo/metodo-modelli.sh fornitori" > "%ELENCO%" 2>nul
if errorlevel 1 (
    echo.
    echo    Non sono riuscito a farmi dare l'elenco dei modelli da OpenCode.
    echo    Controlla che sia installato e che ci sia almeno una chiave: opencode providers
    echo.
    set "MODELLO_MANO="
    set /p "MODELLO_MANO=Scrivi il modello a mano (vuoto = annulla): "
    if not defined MODELLO_MANO goto menu
    set "OPZ_AGENTE= --agente opencode"
    set "OPZ_MODELLO= --model !MODELLO_MANO!"
    set "CHI_LAVORA=OpenCode con !MODELLO_MANO!"
    goto menu
)
echo.
echo    DI CHI SONO I MODELLI CHE PUOI USARE
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("%ELENCO%") do echo      %%A. %%B  (%%C)
echo.
set "FORN_N="
set /p "FORN_N=Quale? [1] "
if not defined FORN_N set "FORN_N=1"
set "FORNITORE="
for /f "usebackq tokens=1,2 delims=|" %%A in ("%ELENCO%") do if "%%A"=="!FORN_N!" set "FORNITORE=%%B"
if not defined FORNITORE (
    echo    Scelta non valida.
    goto menu
)
set "ELENCOM=%TEMP%\metodo-modelli.txt"
"%GITBASH%" -lc "cd '%ROOT%' && ./metodo/metodo-modelli.sh modelli '!FORNITORE!'" > "%ELENCOM%" 2>nul
echo.
echo    MODELLI DI !FORNITORE!
for /f "usebackq tokens=1,2 delims=|" %%A in ("%ELENCOM%") do echo      %%A. %%B
echo.
set "MOD_N="
set /p "MOD_N=Quale modello? [1] "
if not defined MOD_N set "MOD_N=1"
set "MODELLO="
for /f "usebackq tokens=1,2 delims=|" %%A in ("%ELENCOM%") do if "%%A"=="!MOD_N!" set "MODELLO=%%B"
if not defined MODELLO (
    echo    Scelta non valida.
    goto menu
)
set "OPZ_AGENTE= --agente opencode"
set "OPZ_MODELLO= --model !MODELLO!"
set "CHI_LAVORA=OpenCode con !MODELLO!"
goto menu

:corsie_consiglio
set "DESC=Consiglio degli Agenti - tre agenti esaminano la fase e dicono se conviene dividerla"
set "CMD=chmod +x metodo/metodo-corsie.sh && ./metodo/metodo-corsie.sh consiglio"
goto esegui

:corsie_prepara
set "DESC=Apertura delle corsie della fase (si rifiuta se le fondamenta comuni non sono finite)"
set "CMD=chmod +x metodo/metodo-corsie.sh && ./metodo/metodo-corsie.sh prepara"
goto esegui

:corsie_stato
set "DESC=A che punto sono le corsie"
set "CMD=chmod +x metodo/metodo-corsie.sh && ./metodo/metodo-corsie.sh stato"
goto esegui

:corsie_riunisci
set "DESC=Riunione: una corsia per volta, con verifica dopo ognuna - si ferma al primo problema"
set "CMD=chmod +x metodo/metodo-corsie.sh && ./metodo/metodo-corsie.sh riunisci"
goto esegui

:corsie_smonta
set "DESC=Chiusura delle corsie - i rami restano, il lavoro non si perde"
set "CMD=chmod +x metodo/metodo-corsie.sh && ./metodo/metodo-corsie.sh smonta"
goto esegui

rem Avvio in parallelo: una finestra per corsia, tutte insieme, con un comando solo.
rem Ogni finestra lavora nella cartella della sua corsia; il runner capisce da solo in
rem quale corsia sta, perche' la deduce dal ramo (vedi --corsia nel runner).
:corsie_avvia
echo.
echo --------------------------------------------------------
echo  Avvio di tutte le corsie, una finestra per corsia
echo --------------------------------------------------------
echo.
if not exist "!CORSIE_WIN!" (
    echo  Nessuna corsia aperta: usa prima la voce 3 del menu.
    echo.
    pause
    goto menu
)
if not defined GITBASH (
    echo  ERRORE: serve Git Bash per avviare le corsie.
    echo  Installa Git for Windows: https://git-scm.com/download/win
    echo.
    pause
    goto menu
)
set "QUANTE=0"
for /d %%C in ("!CORSIE_WIN!\*") do (
    set "NOME=%%~nxC"
    set "DIR_WIN=%%~fC"
    set "DIR_BASH=!DIR_WIN:\=/!"
    echo  Avvio corsia !NOME!...
    start "corsia !NOME! - %PROJ%" "%GITBASH%" -c "cd '!DIR_BASH!' && chmod +x metodo/metodo-villa-runner.sh && ./metodo/metodo-villa-runner.sh --timeout 60 --verbose; echo; echo '=== corsia !NOME! terminata ==='; read -p 'Premi Invio per chiudere...'"
    set /a QUANTE+=1
)
echo.
if "!QUANTE!"=="0" (
    echo  Nessuna corsia trovata in !CORSIE_WIN!
) else (
    echo  !QUANTE! corsie avviate, ognuna nella sua finestra.
    echo  Le notifiche arrivano tutte nella stessa sezione del gruppo, con il nome della corsia in cima.
)
echo.
pause
goto menu

:aggiorna
set "DESC=Aggiornamento del Metodo dalla fonte ufficiale (non committa nulla: rivedi tu)"
set "CMD=chmod +x metodo/metodo-sync.sh && ./metodo/metodo-sync.sh scarica"
goto esegui

:rimanda
set "DESC=Proposta di miglioria al Metodo - ANTEPRIMA, non invia niente"
set "CMD=chmod +x metodo/metodo-sync.sh && ./metodo/metodo-sync.sh rimanda"
goto esegui

:esegui
echo.
echo --------------------------------------------------------
echo  %DESC%
echo --------------------------------------------------------
echo.

rem GITBASH e' gia' stato cercato in cima al file: qui si usa e basta.
if defined GITBASH (
    "%GITBASH%" -c "cd '!ROOT!' && !CMD!"
    goto terminato
)

where wsl >nul 2>&1
if %ERRORLEVEL%==0 (
    echo  Git Bash non trovato, uso WSL.
    set "ROOT_WSL=!ROOT:C:=/mnt/c!"
    wsl bash -c "cd '!ROOT_WSL!' && !CMD!"
    goto terminato
)

echo  ERRORE: non ho trovato ne' Git Bash ne' WSL.
echo  Installa Git for Windows: https://git-scm.com/download/win
echo.
pause
goto fine

:terminato
echo.
echo === Terminato ===
echo.
pause

:fine
endlocal

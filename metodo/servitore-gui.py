#!/usr/bin/env python
"""Il servitore della schermata del runner: sta fra la pagina e il computer di Villa.

Una pagina aperta con doppio clic non puo' far partire un programma, e non puo' leggere
i file del progetto. Serve qualcuno in mezzo. Questo e' quel qualcuno, e fa tre cose:

    1. serve la pagina                      GET  /            (metodo/gui/)
    2. dice a che punto e' il progetto      GET  /api/stato
       chi puo' lavorare / quanta benzina   GET  /api/modelli · GET  /api/benzina
       il blocco in corso e la cronologia   GET  /api/durante
    3. costruisce il comando e lo lancia    POST /api/lancia
       chiede al runner di fermarsi         POST /api/ferma

NON DECIDE NIENTE. Non interpreta la roadmap (lo fa metodo-roadmap.sh, tramite
stato-progetto.sh), non sceglie chi lavora, non calcola previsioni: quelle regole vivono
nel runner e restano li'. Qui si legge, si costruisce una riga di comando e si lancia.
Il giorno in cui questo file cominciasse a decidere, il Metodo avrebbe due teste che
possono dire cose diverse.

    python metodo/servitore-gui.py [--porta N] [--cartella DIR]
    python metodo/servitore-gui.py comando   < impostazioni.json
    python metodo/servitore-gui.py apri [--porta N] [--cartella DIR] [--senza-browser]

Il secondo modo non avvia niente: stampa il comando che verrebbe lanciato, un argomento
per riga. Serve alle prove e a chi vuole vedere cosa sta per succedere. Il terzo e' il
doppio clic (schermata.bat): accende il servitore se e' spento — in una finestra tutta
sua, ridotta a icona — e apre il browser; se la schermata e' gia' aperta, apre il
browser e basta. Un secondo servitore non parte mai.

SICUREZZA — questo programma esegue comandi sul computer di Villa, quindi:
- ascolta SOLO su 127.0.0.1: dalla rete non e' raggiungibile;
- pretende che l'indirizzo chiesto sia localhost (un nome di dominio che punta al
  computer di casa non basta: e' il modo classico per farsi aprire una porta locale
  da un sito qualunque);
- per lanciare pretende un'intestazione tutta sua, che una pagina di un altro sito non
  puo' mettere senza chiedere prima il permesso — permesso che qui non si da' mai;
- le impostazioni che arrivano dalla pagina si convalidano una per una, e una chiave
  sconosciuta e' un errore, non una cosa da ignorare: una corsa partita con
  impostazioni diverse da quelle che si vedono a schermo e' peggio di una che non parte;
- il comando si lancia come lista di argomenti, mai attraverso una shell.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse, parse_qs, unquote
from urllib.request import urlopen

PORTA_DI_CASA = 8756
# L'intestazione che la pagina mette e un sito estraneo non puo' mettere (la metterebbe
# solo dopo un permesso preventivo, che questo servitore non concede a nessuno).
INTESTAZIONE_NOSTRA = "X-Metodo-Villa"
TIMEOUT_STRUMENTI = 90          # secondi: chiedere i modelli o la benzina passa dalla rete

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE_METODO = os.path.dirname(QUI)

# --- Le impostazioni che la pagina puo' mandare, e nient'altro -------------------------
#
# Una per una, con il valore ammesso scritto qui accanto. Chi aggiunge un'opzione al
# runner e la vuole sulla schermata la aggiunge QUI: e' l'unico punto in cui la pagina
# puo' influire su cosa viene eseguito.
AGENTI = ("claude", "opencode")
IMPEGNI = ("low", "medium", "high", "max")
MODALITA = ("fase", "tutte")
# I nomi dei modelli hanno la forma "fornitore/modello" o "claude-opus-5": lettere, cifre
# e pochi segni. Tutto il resto non e' un nome di modello, e non deve nemmeno provarci.
NOME_MODELLO = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._/-]{0,79}$")


class ImpostazioneNonValida(Exception):
    """Le impostazioni arrivate dalla pagina non si possono eseguire. Il messaggio e'
    scritto per essere mostrato a schermo: dice cosa non va, non come e' fatto il codice."""


def convalida(grezze):
    """Da quello che arriva dalla pagina a impostazioni di cui ci si puo' fidare."""
    if not isinstance(grezze, dict):
        raise ImpostazioneNonValida("Le impostazioni devono essere un oggetto.")
    note = {"modalita", "agente", "modello", "impegno", "ottimizza", "tetto",
            "timeout", "prova_a_vuoto"}
    sconosciute = sorted(set(grezze) - note)
    if sconosciute:
        raise ImpostazioneNonValida(
            "Impostazioni che non conosco: %s. Non le eseguo: una corsa partita con "
            "impostazioni diverse da quelle a schermo sarebbe peggio di una corsa non "
            "partita." % ", ".join(sconosciute))

    def scelta(nome, ammessi, default):
        v = grezze.get(nome, default)
        if v is None:
            return None
        if v not in ammessi:
            raise ImpostazioneNonValida(
                "%s: '%s' non e' fra i valori ammessi (%s)." % (nome, v, ", ".join(ammessi)))
        return v

    def numero(nome, default, minimo, massimo):
        v = grezze.get(nome, default)
        # Il vero/falso in Python e' anche un numero: senza questo controllo "tetto": true
        # diventerebbe un tetto di 1 blocco senza che nessuno se ne accorga.
        if isinstance(v, bool) or not isinstance(v, int):
            raise ImpostazioneNonValida("%s dev'essere un numero intero." % nome)
        if not minimo <= v <= massimo:
            raise ImpostazioneNonValida(
                "%s dev'essere fra %d e %d (arrivato %d)." % (nome, minimo, massimo, v))
        return v

    def vero_o_falso(nome):
        v = grezze.get(nome, False)
        if not isinstance(v, bool):
            raise ImpostazioneNonValida("%s dev'essere vero o falso." % nome)
        return v

    modello = grezze.get("modello") or None
    if modello is not None:
        if not isinstance(modello, str) or not NOME_MODELLO.match(modello):
            raise ImpostazioneNonValida(
                "Il nome del modello contiene caratteri che un nome di modello non ha.")

    return {
        "modalita": scelta("modalita", MODALITA, "fase"),
        "agente": scelta("agente", AGENTI, None),
        "modello": modello,
        "impegno": scelta("impegno", IMPEGNI, None),
        "ottimizza": vero_o_falso("ottimizza"),
        # Il tetto e' un paracadute anti-runaway, non la quantita' di lavoro: resta alto.
        "tetto": numero("tetto", 300, 1, 1000),
        "timeout": numero("timeout", 30, 1, 600),
        "prova_a_vuoto": vero_o_falso("prova_a_vuoto"),
    }


def trova_bash():
    """Dove sta bash. Il runner e' uno script di shell, e su Windows non e' nel PATH di
    tutti: si guarda dove Git for Windows lo mette. Chi lo ha altrove lo dice con
    METODO_BASH."""
    scelto = os.environ.get("METODO_BASH")
    if scelto and os.path.isfile(scelto):
        return scelto
    trovato = shutil.which("bash")
    if trovato:
        return trovato
    for p in (r"C:\Program Files\Git\bin\bash.exe",
              r"C:\Program Files (x86)\Git\bin\bash.exe"):
        if os.path.isfile(p):
            return p
    return None


# --- Il doppio clic: accendere il servitore e aprire la schermata -----------------------
#
# Quello che il file da cliccare (schermata.bat) chiede a questo programma. La logica
# sta qui come tutto il resto della macchina: il file in radice cerca solo Python.

def chi_ascolta(porta):
    """Chi risponde sulla porta: 'nostro', 'altro' o 'nessuno'.

    'nostro' solo se chi risponde si presenta come questo servitore: una porta occupata
    da un altro programma non deve diventare una schermata che mostra robe di altri."""
    try:
        with urlopen("http://127.0.0.1:%d/" % porta, timeout=3) as risposta:
            nostro = risposta.headers.get("Server", "").startswith("MetodoVilla")
    except HTTPError as e:
        # Risponde, ma con un errore: e' comunque qualcuno, e l'intestazione c'e' sempre.
        nostro = (e.headers or {}).get("Server", "").startswith("MetodoVilla")
    except URLError as e:
        if isinstance(e.reason, ConnectionRefusedError):
            return "nessuno"
        # Tempo scaduto o connessione chiusa: c'e' qualcosa, ma non parla come noi.
        return "altro"
    except (TimeoutError, OSError):
        return "altro"
    return "nostro" if nostro else "altro"


def percorsi_uguali(a, b):
    """Due scritture dello stesso posto ('C:\\...' come lo scrive Python, '/c/...' come
    lo scrive bash su Windows) sono lo stesso progetto?"""
    def norma(p):
        p = p.strip().replace("\\", "/")
        if len(p) >= 3 and p[0] == "/" and p[1].isalpha() and p[2] == "/":
            p = p[1] + ":" + p[2:]
        return os.path.normcase(os.path.normpath(p))
    return norma(a) == norma(b)


def progetto_servito(porta):
    """Che progetto sta mostrando la schermata gia' aperta, se lo vuole dire.

    Serve a non aprire il browser su una schermata che sta mostrando un altro progetto:
    due progetti sullo stesso computer si dividono la stessa porta di casa."""
    try:
        with urlopen("http://127.0.0.1:%d/api/stato" % porta, timeout=5) as risposta:
            detto = json.load(risposta)
    except (ValueError, OSError):
        # Non lo dice (bash assente, stato in errore): non e' un motivo per non aprire.
        return None
    return detto.get("progetto", {}).get("cartella")


def accendi_servitore(porta, progetto):
    """Avvia il servitore in una finestra tutta sua, ridotta a icona.

    La finestra serve per poterlo spegnere con un clic sulla X, come per qualunque
    programma: senza, spegnerlo vorrebbe dire andare a cercarlo a mano. Quello che
    stampa va su un registro di lavoro nella cartella temporanea: cosi', se muore
    subito, il motivo resta leggibile invece di sparire insieme alla finestra."""
    registro = os.path.join(tempfile.gettempdir(), "metodo-villa-servitore.log")
    comando = [sys.executable, os.path.abspath(__file__),
               "--porta", str(porta), "--cartella", progetto]
    extra = {}
    if os.name == "nt":
        avvio = subprocess.STARTUPINFO()
        avvio.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        avvio.wShowWindow = 6          # ridotta a icona (SW_MINIMIZE)
        extra = {"startupinfo": avvio, "creationflags": subprocess.CREATE_NEW_CONSOLE}
    # Il figlio riconosce da questa variabile che la finestra e' la sua: gli serve per
    # metterle un titolo che dica cosa si sta spegnendo con un clic.
    ambiente = dict(os.environ, METODO_FINESTRA_DEDICATA="si")
    uscita = open(registro, "w", encoding="utf-8", errors="replace")
    try:
        processo = subprocess.Popen(comando, stdin=subprocess.DEVNULL,
                                    stdout=uscita, stderr=subprocess.STDOUT,
                                    env=ambiente, **extra)
    finally:
        # Il figlio ha la sua copia del file aperto: qui non serve piu'.
        uscita.close()
    return processo, registro


def coda_del_registro(registro, quante=15):
    """Le ultime righe scritte dal servitore: quel che serve a dire perche' e' morto."""
    try:
        with open(registro, encoding="utf-8", errors="replace") as f:
            return "".join(f.readlines()[-quante:]).strip() or "(non ha scritto niente)"
    except OSError:
        return "(non ha scritto niente)"


def aspetta_la_schermata(processo, porta, registro, quanto=20):
    """Aspetta che il servitore appena acceso cominci a rispondere.

    Vero se la schermata e' pronta — l'ha accesa anche qualcun altro, un doppio clic
    arrivato quasi insieme al nostro: per noi e' comunque un successo. Falso se il
    servitore muore o se il tempo scade, e in entrambi i casi il motivo e' gia'
    stato scritto."""
    for _ in range(int(quanto / 0.25)):
        time.sleep(0.25)
        if chi_ascolta(porta) == "nostro":
            return True
        if processo.poll() is not None:
            print("Il servitore si e' spento appena partito. Ecco le ultime cose che "
                  "ha detto:\n" + coda_del_registro(registro), file=sys.stderr)
            return False
    print("Il servitore non ha cominciato a rispondere entro %d secondi. Prova ad "
          "avviarlo a mano e leggi cosa dice:\n  python metodo/servitore-gui.py" % quanto,
          file=sys.stderr)
    return False


def apri_browser(url, senza_browser):
    """Aprire il browser non e' mai un motivo per fallire: il servitore e' acceso, e
    l'indirizzo resta scritto anche quando il browser non si apre."""
    if senza_browser:
        print("(Browser lasciato stare: la schermata e' su %s)" % url)
        return 0
    if webbrowser.open(url):
        return 0
    print("Non sono riuscito ad aprire il browser: la schermata e' su %s" % url)
    return 0


def apri_schermata(argomenti):
    """Il doppio clic: la schermata spenta si accende, quella accesa si riapre e basta.

    Un secondo servitore non parte mai: due servitori sullo stesso progetto si
    accavallerebbero, e due schermate che dicono cose diverse sarebbero peggio di una."""
    porta, progetto, senza_browser = PORTA_DI_CASA, RADICE_METODO, False
    try:
        i = 0
        while i < len(argomenti):
            if argomenti[i] == "--porta" and i + 1 < len(argomenti):
                porta = int(argomenti[i + 1]); i += 2
            elif argomenti[i] == "--cartella" and i + 1 < len(argomenti):
                progetto = os.path.abspath(argomenti[i + 1]); i += 2
            elif argomenti[i] == "--senza-browser":
                senza_browser = True; i += 1
            else:
                print("Uso: servitore-gui.py apri [--porta N] [--cartella DIR] "
                      "[--senza-browser]", file=sys.stderr)
                return 1
    except ValueError:
        print("La porta dev'essere un numero.", file=sys.stderr)
        return 1
    url = "http://127.0.0.1:%d" % porta

    if trova_bash() is None:
        print("Avviso: non trovo bash. La schermata si aprira' lo stesso, ma non sapra' "
              "leggere lo stato del progetto ne' lanciare corse (serve Git for Windows).")

    come = chi_ascolta(porta)
    if come == "altro":
        print("Sulla porta %d risponde un programma che non e' la schermata del runner "
              "(o non risponde affatto). Chiudilo e riprova, oppure scegli un'altra "
              "porta con --porta." % porta, file=sys.stderr)
        return 1
    if come == "nostro":
        servito = progetto_servito(porta)
        if servito and not percorsi_uguali(servito, progetto):
            print("La schermata e' gia' aperta, ma sta mostrando un altro progetto (%s).\n"
                  "Chiudi la finestra 'Metodo Villa — la schermata del runner' (quella "
                  "ridotta a icona) e riprova col doppio clic." % servito, file=sys.stderr)
            return 1
        print("La schermata e' gia' aperta: ti ci riporto col browser.")
        return apri_browser(url, senza_browser)

    print("Accendo il servitore della schermata...")
    processo, registro = accendi_servitore(porta, progetto)
    if not aspetta_la_schermata(processo, porta, registro):
        return 1
    print("La schermata del runner e' su %s" % url)
    return apri_browser(url, senza_browser)


def costruisci_comando(impostazioni, runner, bash):
    """Dalle impostazioni convalidate alla riga di comando del runner.

    Le opzioni si scrivono nello stesso ordine in cui il runner le documenta, cosi' chi
    legge il comando a schermo ritrova quello che leggerebbe nell'aiuto. Le impostazioni
    non scelte NON si scrivono: se non compaiono, comanda la configurazione del progetto
    (.env.runner) — che e' esattamente quello che fa il runner lanciato a mano.
    """
    cmd = [bash, runner]
    if impostazioni["modalita"] == "tutte":
        cmd.append("--tutte-le-fasi")
    if impostazioni["agente"]:
        cmd += ["--agente", impostazioni["agente"]]
    if impostazioni["modello"]:
        cmd += ["--model", impostazioni["modello"]]
    if impostazioni["impegno"]:
        cmd += ["--impegno", impostazioni["impegno"]]
    # Se e' stato scelto un modello a mano, l'instradamento si spegne da solo: la regola e'
    # del runner (cap. 22) e li' resta. Qui si passa quello che Villa ha chiesto, senza
    # correggerlo di nascosto — cosi' il runner puo' anche dirlo a schermo.
    if impostazioni["ottimizza"]:
        cmd.append("--ottimizza")
    cmd += ["--max-blocks", str(impostazioni["tetto"])]
    cmd += ["--timeout", str(impostazioni["timeout"])]
    if impostazioni["prova_a_vuoto"]:
        cmd.append("--dry-run")
    return cmd


def leggi_righe_stato(progetto, modalita="fase", tetto=300, fase=""):
    """Lo stato del progetto, chiesto a chi lo sa: stato-progetto.sh.

    Modalita', tetto e fase servono alla previsione ("quanto manca a questa corsa"):
    la regola del conto sta in metodo-roadmap.sh, condivisa col runner — qui si passano
    soltanto. Torna (dizionario, elenco delle fasi, previsione o None) oppure alza
    OSError con il motivo."""
    strumento = os.path.join(QUI, "stato-progetto.sh")
    bash = trova_bash()
    if bash is None:
        raise OSError("Non trovo bash: senza, non posso leggere lo stato del progetto "
                      "ne' lanciare il runner. Installa Git for Windows o indica dove "
                      "sta bash con METODO_BASH.")
    fatto = subprocess.run([bash, strumento, progetto, modalita, str(tetto), fase],
                           capture_output=True, text=True,
                           encoding="utf-8", errors="replace", timeout=TIMEOUT_STRUMENTI)
    if fatto.returncode != 0:
        raise OSError(fatto.stderr.strip() or "Non riesco a leggere lo stato del progetto.")
    valori, fasi, previsione = {}, [], None
    for riga in fatto.stdout.splitlines():
        pezzi = riga.split("|")
        if pezzi[0] == "fase" and len(pezzi) == 4:
            fasi.append({"nome": pezzi[1], "fatti": int(pezzi[2]), "da_fare": int(pezzi[3])})
        elif pezzi[0] == "previsione" and len(pezzi) == 3:
            previsione = {"blocchi": int(pezzi[1]) if pezzi[1].isdigit() else None,
                          "motivo": pezzi[2]}
        elif len(pezzi) == 2:
            valori[pezzi[0]] = pezzi[1]
    return valori, fasi, previsione


def leggi_punto(progetto):
    """Da dove riparte il lavoro: sta scritto in progress.json, che lo scrive il runner."""
    percorso = os.path.join(progetto, "docs", "diario", "progress.json")
    try:
        with open(percorso, encoding="utf-8") as f:
            d = json.load(f)
    except FileNotFoundError:
        return {"noto": False, "motivo": "Il progetto non ha ancora un punto di partenza: "
                                         "nessuna corsa e' mai stata fatta."}
    except (ValueError, OSError) as e:
        return {"noto": False, "motivo": "Il file del punto di partenza non si legge (%s)." % e}
    return {"noto": True,
            "fase": str(d.get("current_phase", "")),
            "blocco": str(d.get("current_block", "")),
            "stato": d.get("status", ""),
            "ultima_corsa": d.get("last_run", "")}


# --- Il momento DURANTE: il record del runner e la cronologia della corsa ---------------
#
# Il runner lascia due tracce mentre lavora: il record "in corso" (durante.json, riscritto
# a ogni blocco) e il diario di sessione (una voce per blocco chiuso). Qui si leggono e
# si passano alla pagina cosi' come sono: la forma dei dati e' del runner, non di chi
# sta in mezzo.

# Le etichette delle righe del diario diventano le chiavi della risposta. Una voce
# scritta prima che un campo esistesse semplicemente non ce l'ha: il diario vecchio
# continua a leggersi, regola del Blocco 5.2.
CAMPI_DIARIO = {"Status": "status", "Summary": "summary", "Per Villa": "per_villa",
                "Consumo": "consumo", "Motore": "motore", "Durata": "durata",
                "File": "file", "Verifica": "verifica"}


def leggi_cronologia(percorso, da_quando=""):
    """I blocchi chiusi di questa corsa, il piu' recente in cima.

    Si leggono dal diario di sessione, e solo le voci scritte dall'inizio della corsa
    in poi: la cronologia e' di QUESTA corsa, l'archivio storico resta nei diari (mappa
    dell'esperienza, "Cosa NON c'e'"). Le date si confrontano come stringhe: hanno la
    stessa forma ("2026-08-16 04:57:00") e l'ordine alfabetico e' quello giusto."""
    try:
        with open(percorso, encoding="utf-8", errors="replace") as f:
            testo = f.read()
    except OSError:
        return []
    voci, corrente, chiave = [], None, None
    for riga in testo.splitlines():
        intestazione = re.match(r"## (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) — Blocco (\S+)",
                                riga)
        if intestazione:
            corrente = {"quando": intestazione.group(1), "blocco": intestazione.group(2)}
            voci.append(corrente)
            chiave = None
            continue
        if corrente is None:
            continue
        campo = re.match(r"- \*\*([^*]+)\*\*: (.*)", riga)
        if campo:
            chiave = CAMPI_DIARIO.get(campo.group(1))
            if chiave:
                corrente[chiave] = campo.group(2)
        elif riga.strip() == "---":
            corrente = None
            chiave = None
        elif chiave and riga.strip():
            # Le righe di seguito: il racconto per Villa e' parlato e va a capo dove
            # vuole. Restano attaccate al campo che stanno seguendo.
            corrente[chiave] += "\n" + riga
    if da_quando:
        voci = [v for v in voci if v["quando"] >= da_quando]
    for voce in voci:
        if "file" in voce:
            voce["file"] = [p.strip() for p in voce["file"].split(",") if p.strip()]
    voci.reverse()
    return voci


def processo_vivo(pid):
    """Quel numero di processo sta ancora girando?

    Serve a rispondere alla domanda che conta prima di lanciare: c'e' gia' un runner su
    questo progetto? La data di fine scritta nel record non basta — un runner ucciso di
    forza non fa in tempo a scriverla, e la schermata resterebbe bloccata per sempre.
    Su Windows NON si usa os.kill nemmeno col segnale zero: li' os.kill termina il
    processo davvero, e chiedere "sei vivo?" ammazzerebbe la corsa."""
    if not isinstance(pid, int) or pid <= 0:
        return False
    if os.name == "nt":
        import ctypes
        PROCESSO_INTERROGABILE, ANCORA_VIVO = 0x1000, 259
        kernel = ctypes.windll.kernel32
        maniglia = kernel.OpenProcess(PROCESSO_INTERROGABILE, False, pid)
        if not maniglia:
            return False
        try:
            codice = ctypes.c_ulong()
            if not kernel.GetExitCodeProcess(maniglia, ctypes.byref(codice)):
                return False
            return codice.value == ANCORA_VIVO
        finally:
            kernel.CloseHandle(maniglia)
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    return True


def corsa_dal_record(progetto):
    """La corsa che risulta dal record del runner, se ce n'e' una ancora viva.

    Copre il caso che la Corsa qui sotto non puo' conoscere: una corsa avviata da
    runner.bat o dal terminale. Un record senza numero di processo (scritto da un runner
    piu' vecchio) non fa dire niente: meglio non sapere che affermare il falso."""
    percorso = os.path.join(progetto, "docs", "diario", "durante.json")
    try:
        with open(percorso, encoding="utf-8") as f:
            corsa = (json.load(f) or {}).get("corsa") or {}
    except (ValueError, OSError):
        return None
    if corsa.get("finita_il") or not processo_vivo(corsa.get("pid")):
        return None
    return {"in_corso": True, "avviata_il": corsa.get("iniziata_il"),
            "pid": corsa.get("pid"), "da_questa_schermata": False,
            "comando": None, "registro": None}


def quadro_della_corsa(progetto, corsa_locale):
    """Chi sta girando su questo progetto, comunque sia stato avviato.

    Prima si guarda la corsa di questa schermata: di quella si sa tutto, compreso il
    comando. Poi il record del runner, che e' l'unico modo di accorgersi di una corsa
    partita da runner.bat — e due runner sullo stesso progetto si sovrascrivono a
    vicenda il punto in cui sono arrivati."""
    quadro = corsa_locale.quadro()
    if quadro["in_corso"]:
        return quadro
    return corsa_dal_record(progetto) or quadro


def percorso_richiesta_di_fermarsi(progetto):
    """Dove si lascia scritto al runner di fermarsi. Il nome del file e' lo stesso che il
    runner cerca: se cambia qui, cambia li' (FERMA_FILE in metodo-villa-runner.sh)."""
    return os.path.join(progetto, "docs", "diario", "ferma-la-corsa")


class Corsa:
    """La corsa lanciata da questa schermata: una sola per volta.

    Vive nel servitore, non nella pagina: chiudere la finestra del browser non ferma il
    lavoro, e riaprendola si ritrova la corsa in corso."""

    def __init__(self):
        self._lucchetto = threading.Lock()
        self._processo = None
        self._comando = None
        self._avviata_il = None
        self._registro = None

    def in_corso(self):
        with self._lucchetto:
            return self._processo is not None and self._processo.poll() is None

    def quadro(self):
        with self._lucchetto:
            viva = self._processo is not None and self._processo.poll() is None
            return {"in_corso": viva,
                    "da_questa_schermata": viva,
                    "comando": self._comando if self._processo is not None else None,
                    "avviata_il": self._avviata_il,
                    "registro": self._registro,
                    "pid": self._processo.pid if viva else None}

    def avvia(self, comando, cartella, registro):
        with self._lucchetto:
            if self._processo is not None and self._processo.poll() is None:
                raise RuntimeError("Una corsa e' gia' in corso su questo progetto. "
                                   "Due runner sullo stesso progetto si sovrascrivono "
                                   "il punto in cui sono arrivati.")
            os.makedirs(os.path.dirname(registro), exist_ok=True)
            uscita = open(registro, "w", encoding="utf-8", errors="replace")
            try:
                self._processo = subprocess.Popen(
                    comando, cwd=cartella, stdin=subprocess.DEVNULL,
                    stdout=uscita, stderr=subprocess.STDOUT)
            finally:
                # Il figlio ha la sua copia del file aperto: qui non serve piu'.
                uscita.close()
            self._comando = comando
            self._registro = registro
            self._avviata_il = time.strftime("%Y-%m-%dT%H:%M:%S")
            return self._processo.pid


class Servitore(BaseHTTPRequestHandler):
    server_version = "MetodoVilla"
    sys_version = ""

    # --- le buone maniere ---------------------------------------------------------
    def log_message(self, formato, *args):
        # Il registro di serie scrive una riga per ogni immagine e per ogni foglio di
        # stile: qui si tiene solo cio' che serve a capire se il servitore risponde.
        # Il testo si prende com'e' da chi chiama (anche gli errori passano di qui, e non
        # hanno lo stesso numero di pezzi delle richieste normali).
        if getattr(self, "path", "").startswith("/api/"):
            sys.stderr.write("  %s\n" % (formato % args))

    def rispondi(self, codice, corpo, tipo="application/json; charset=utf-8"):
        dati = corpo if isinstance(corpo, bytes) else corpo.encode("utf-8")
        self.send_response(codice)
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(dati)))
        # Niente intestazioni che aprano la porta ad altri siti: la schermata e' l'unica
        # cosa che deve poter leggere queste risposte.
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(dati)

    def rispondi_json(self, codice, oggetto):
        self.rispondi(codice, json.dumps(oggetto, ensure_ascii=False, indent=2))

    def errore(self, codice, messaggio):
        self.rispondi_json(codice, {"errore": messaggio})

    def indirizzo_di_casa(self):
        """Vero se la richiesta e' arrivata all'indirizzo del computer di casa.

        Un sito qualunque puo' avere un nome di dominio che punta a 127.0.0.1: senza
        questo controllo, aprire quel sito basterebbe a fargli parlare con il servitore."""
        nome = self.headers.get("Host", "").rsplit(":", 1)[0].strip("[]").lower()
        return nome in ("localhost", "127.0.0.1", "::1", "")

    def provenienza_ammessa(self):
        """La pagina che chiede dev'essere la nostra, o nessuna (una richiesta fatta da
        uno strumento, che non manda la provenienza)."""
        origine = self.headers.get("Origin")
        if origine is None:
            return True
        pezzi = urlparse(origine)
        return (pezzi.scheme == "http"
                and pezzi.hostname in ("localhost", "127.0.0.1")
                and pezzi.port == self.server.server_port)

    def controlli_di_ingresso(self):
        if not self.indirizzo_di_casa():
            self.errore(403, "Questo servitore risponde solo a chi lo chiama da questo "
                             "computer, all'indirizzo di casa.")
            return False
        if not self.provenienza_ammessa():
            self.errore(403, "Richiesta arrivata da una pagina che non e' la schermata "
                             "del runner.")
            return False
        return True

    # --- le risposte ---------------------------------------------------------------
    def do_GET(self):
        if not self.controlli_di_ingresso():
            return
        percorso = urlparse(self.path).path
        if percorso == "/api/stato":
            return self.stato()
        if percorso == "/api/modelli":
            return self.modelli()
        if percorso == "/api/benzina":
            return self.benzina()
        if percorso == "/api/durante":
            return self.durante()
        if percorso.startswith("/api/"):
            return self.errore(404, "Non conosco questa richiesta: %s" % percorso)
        return self.pagina(percorso)

    def do_POST(self):
        if not self.controlli_di_ingresso():
            return
        if self.headers.get(INTESTAZIONE_NOSTRA) != "si":
            return self.errore(403,
                               "Manca il segno di riconoscimento della schermata. Non "
                               "lancio niente su richiesta di una pagina che non conosco.")
        percorso = urlparse(self.path).path
        if percorso == "/api/lancia":
            return self.lancia()
        if percorso == "/api/ferma":
            return self.ferma()
        return self.errore(404, "Non conosco questa richiesta: %s" % percorso)

    def stato(self):
        progetto = self.server.progetto
        # La previsione dipende da come la corsa e' impostata: la pagina puo' chiedere lo
        # stato per l'altra modalita' o per un tetto diverso, e la risposta cambia.
        richiesta = parse_qs(urlparse(self.path).query)
        modalita = richiesta.get("modalita", ["fase"])[0]
        if modalita not in MODALITA:
            return self.errore(400, "modalita': '%s' non e' fra i valori ammessi (%s)."
                                    % (modalita, ", ".join(MODALITA)))
        tetto_letto = richiesta.get("tetto", [""])[0]
        tetto = 300
        if tetto_letto:
            if not tetto_letto.isdigit() or not 1 <= int(tetto_letto) <= 1000:
                return self.errore(400, "Il tetto dev'essere un numero fra 1 e 1000.")
            tetto = int(tetto_letto)
        risposta = {"punto": leggi_punto(progetto),
                    "corsa": quadro_della_corsa(progetto, self.server.corsa)}
        fase = risposta["punto"].get("fase", "") if risposta["punto"].get("noto") else ""
        try:
            valori, fasi, previsione = leggi_righe_stato(progetto, modalita, tetto, fase)
        except (OSError, subprocess.SubprocessError) as e:
            risposta["errore"] = str(e)
            return self.rispondi_json(500, risposta)
        if previsione is not None:
            risposta["previsione"] = previsione
        risposta["progetto"] = {"nome": valori.get("progetto", ""),
                                "cartella": valori.get("cartella", progetto),
                                "ramo": valori.get("ramo", "")}
        risposta["impostazioni_di_partenza"] = {
            "agente": valori.get("agente", ""),
            "modello": valori.get("modello") or None,
            "impegno": valori.get("impegno", ""),
            "ottimizza": valori.get("ottimizza") == "si",
            "tetto": int(valori.get("tetto", 300)),
            "timeout": int(valori.get("timeout", 30)),
        }
        if valori.get("roadmap") == "si":
            risposta["roadmap"] = {"disponibile": True,
                                   "fatti": int(valori.get("roadmap_fatti", 0)),
                                   "da_fare": int(valori.get("roadmap_da_fare", 0)),
                                   "fasi": fasi}
        else:
            risposta["roadmap"] = {"disponibile": False,
                                   "motivo": "Il progetto non ha una ROADMAP.md: non so "
                                             "dire quanto lavoro resta."}
        return self.rispondi_json(200, risposta)

    def modelli(self):
        """Chi puo' lavorare davvero su questa macchina: solo i modelli per cui esiste una
        chiave. Lo sa metodo-modelli.sh, e lo sa lui soltanto.

        Senza parametro: i fornitori. ?fornitore=NOME: i modelli di quel fornitore.
        ?fornitore=*: tutti i modelli in una chiamata sola (il catalogo di OpenCode si
        legge una volta: chiederlo per fornitore vorrebbe dire rileggero ogni volta)."""
        fornitore = parse_qs(urlparse(self.path).query).get("fornitore", [""])[0]
        if fornitore and fornitore != "*" and not NOME_MODELLO.match(fornitore):
            return self.errore(400, "Nome di fornitore non valido.")
        bash = trova_bash()
        if bash is None:
            return self.errore(500, "Non trovo bash su questo computer.")
        argomenti = [bash, os.path.join(QUI, "metodo-modelli.sh")]
        if fornitore == "*":
            argomenti += ["modelli"]
        elif fornitore:
            argomenti += ["modelli", fornitore]
        else:
            argomenti += ["fornitori"]
        try:
            fatto = subprocess.run(argomenti, capture_output=True, text=True,
                                   encoding="utf-8", errors="replace",
                                   timeout=TIMEOUT_STRUMENTI)
        except subprocess.SubprocessError as e:
            return self.errore(500, "Non sono riuscito a chiedere l'elenco dei modelli (%s)." % e)
        if fatto.returncode != 0:
            return self.rispondi_json(200, {"disponibile": False,
                                            "motivo": fatto.stderr.strip() or
                                            "Nessun modello utilizzabile.",
                                            "voci": []})
        voci = []
        for riga in fatto.stdout.splitlines():
            pezzi = riga.split("|")
            if len(pezzi) >= 2:
                voci.append({"nome": pezzi[1], "nota": pezzi[2] if len(pezzi) > 2 else ""})
        return self.rispondi_json(200, {"disponibile": True, "voci": voci})

    def benzina(self):
        """Quanta quota e quanto saldo restano. Il conto lo fa leggi-benzina.py: qui si
        passa la risposta cosi' com'e', senza toccarla."""
        try:
            fatto = subprocess.run([sys.executable, os.path.join(QUI, "leggi-benzina.py")],
                                   capture_output=True, text=True, encoding="utf-8",
                                   errors="replace", timeout=TIMEOUT_STRUMENTI)
            return self.rispondi(200 if fatto.returncode == 0 else 500,
                                 fatto.stdout or json.dumps(
                                     {"errore": fatto.stderr.strip() or
                                      "La spia della benzina non ha risposto."},
                                     ensure_ascii=False))
        except subprocess.SubprocessError as e:
            return self.errore(500, "La spia della benzina non ha risposto (%s)." % e)

    def durante(self):
        """Il momento DURANTE della schermata: il blocco che sta girando adesso e la
        cronologia di questa corsa. Non si calcola niente: si legge il record che il
        runner riscrive a ogni blocco (durante.json) e il diario di sessione, dove i
        blocchi chiusi si raccontano gia' da soli."""
        diario = os.path.join(self.server.progetto, "docs", "diario")
        try:
            with open(os.path.join(diario, "durante.json"), encoding="utf-8") as f:
                record = json.load(f)
        except FileNotFoundError:
            return self.rispondi_json(200, {
                "disponibile": False,
                "motivo": "Nessuna corsa ha ancora lasciato il suo record qui: il file "
                          "del 'mentre lavora' si scrive alla prossima corsa."})
        except (ValueError, OSError) as e:
            return self.rispondi_json(200, {
                "disponibile": False,
                "motivo": "Il record della corsa non si legge (%s)." % e})
        corsa = record.get("corsa") or {}
        cronologia = leggi_cronologia(os.path.join(diario, "session-log.md"),
                                      corsa.get("iniziata_il", ""))
        return self.rispondi_json(200, {
            "disponibile": True, "corsa": corsa,
            # Il record dice cosa stava girando, non se il runner e' ancora vivo: la
            # schermata guarda solo qui mentre lavora, e deve accorgersi da sola quando la
            # corsa e' finita (o e' morta di brutto senza scrivere la data di fine).
            "corsa_viva": quadro_della_corsa(self.server.progetto, self.server.corsa)["in_corso"],
            "in_corso": record.get("in_corso"),
            # Il file c'e' finche' il runner non lo raccoglie, cioe' finche' il blocco in
            # corso non e' finito: e' esattamente quello che la schermata deve dire.
            "ferma_chiesta": os.path.isfile(percorso_richiesta_di_fermarsi(self.server.progetto)),
            "cronologia": cronologia})

    def lancia(self):
        lunghezza = int(self.headers.get("Content-Length") or 0)
        if lunghezza > 64 * 1024:
            return self.errore(413, "Impostazioni troppo lunghe per essere vere.")
        try:
            grezze = json.loads(self.rfile.read(lunghezza).decode("utf-8")) if lunghezza else {}
        except (ValueError, UnicodeDecodeError):
            return self.errore(400, "Le impostazioni non si leggono.")
        try:
            impostazioni = convalida(grezze)
        except ImpostazioneNonValida as e:
            return self.errore(400, str(e))

        progetto = self.server.progetto
        # Una corsa avviata da runner.bat non passa da qui, ma il progetto e' lo stesso:
        # lanciarne una seconda vorrebbe dire due runner che si riscrivono a vicenda il
        # punto in cui sono arrivati.
        gia_in_corso = quadro_della_corsa(progetto, self.server.corsa)
        if gia_in_corso["in_corso"] and not gia_in_corso["da_questa_schermata"]:
            return self.errore(409, "Su questo progetto sta gia' girando una corsa, avviata "
                                    "fuori da questa schermata%s. Due runner sullo stesso "
                                    "progetto si sovrascrivono il punto in cui sono arrivati."
                                    % (" (partita il %s)" % gia_in_corso["avviata_il"]
                                       if gia_in_corso.get("avviata_il") else ""))
        runner = os.path.join(progetto, "metodo", "metodo-villa-runner.sh")
        if not os.path.isfile(runner):
            return self.errore(500, "In questo progetto non trovo il runner del Metodo "
                                    "(metodo/metodo-villa-runner.sh).")
        bash = trova_bash()
        if bash is None:
            return self.errore(500, "Non trovo bash: senza non posso lanciare il runner. "
                                    "Installa Git for Windows o indica dove sta bash con "
                                    "METODO_BASH.")
        comando = costruisci_comando(impostazioni, runner, bash)
        # Dove finisce quello che il runner stampa a schermo. Non e' il registro del Metodo
        # (quello se lo scrive il runner in runner-log.txt): serve a non perdere l'unico
        # caso in cui il runner non arriva nemmeno a scrivere il suo — quando muore prima
        # di partire. Estensione .log perche' e' roba di macchina, e come tale non entra
        # in git.
        registro = os.path.join(progetto, "docs", "diario", "corsa-dalla-schermata.log")
        try:
            pid = self.server.corsa.avvia(comando, progetto, registro)
        except RuntimeError as e:
            return self.errore(409, str(e))
        except OSError as e:
            return self.errore(500, "Il runner non e' partito (%s)." % e)
        return self.rispondi_json(200, {"avviata": True, "pid": pid, "comando": comando,
                                        "registro": registro})

    def ferma(self):
        """Fermarsi dopo il blocco in corso. Non si uccide niente: si lascia scritto, e il
        runner lo trova fra un blocco e l'altro. Un blocco troncato a meta' lascerebbe il
        progetto in uno stato che nessuno ha verificato — l'opposto di cio' che serve."""
        progetto = self.server.progetto
        if not quadro_della_corsa(progetto, self.server.corsa)["in_corso"]:
            return self.errore(409, "Non risulta nessuna corsa in corso su questo progetto: "
                                    "non c'e' niente da fermare.")
        richiesta = percorso_richiesta_di_fermarsi(progetto)
        try:
            os.makedirs(os.path.dirname(richiesta), exist_ok=True)
            with open(richiesta, "w", encoding="utf-8") as f:
                f.write("Fermarsi alla fine del blocco in corso — chiesto dalla schermata "
                        "il %s.\n" % time.strftime("%Y-%m-%d %H:%M:%S"))
        except OSError as e:
            return self.errore(500, "Non sono riuscito a lasciare la richiesta di fermarsi "
                                    "(%s)." % e)
        return self.rispondi_json(200, {"chiesto": True})

    def pagina(self, percorso):
        """La schermata vera e propria. Il servitore la serve; chi la scrive e' il blocco
        che viene dopo, e finche' non c'e' si dice a parole invece di dare pagina bianca."""
        cartella = os.path.join(QUI, "gui")
        # Si scioglie prima quello che il browser ha scritto in codice (%20 negli spazi, ma
        # anche %2e%2e nei puntini): il controllo va fatto sul percorso vero, non su quello
        # travestito.
        relativo = unquote(percorso).lstrip("/\\") or "index.html"
        # Il file servito dev'essere DENTRO metodo/gui: senza questo controllo, un percorso
        # con dei "puntini" farebbe leggere qualunque file del computer.
        assoluto = os.path.normpath(os.path.join(cartella, relativo))
        if not assoluto.startswith(cartella + os.sep):
            return self.errore(403, "Fuori dalla cartella della schermata.")
        if not os.path.isfile(assoluto):
            if relativo == "index.html":
                return self.rispondi(200, PAGINA_PROVVISORIA, "text/html; charset=utf-8")
            return self.errore(404, "Non c'e' nessun file qui: %s" % percorso)
        tipi = {".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8",
                ".js": "text/javascript; charset=utf-8", ".svg": "image/svg+xml",
                ".png": "image/png", ".ico": "image/x-icon",
                ".woff2": "font/woff2", ".json": "application/json; charset=utf-8"}
        with open(assoluto, "rb") as f:
            dati = f.read()
        return self.rispondi(200, dati,
                             tipi.get(os.path.splitext(assoluto)[1], "application/octet-stream"))


PAGINA_PROVVISORIA = """<!doctype html>
<html lang="it"><meta charset="utf-8">
<title>Metodo Villa — la schermata del runner</title>
<style>
  body{background:#101418;color:#e6edf3;font:16px/1.6 system-ui,sans-serif;
       margin:0;display:grid;place-items:center;min-height:100vh}
  main{max-width:34rem;padding:2rem}
  code{background:#1b2229;padding:.15rem .4rem;border-radius:.3rem}
</style>
<main>
  <h1>Il servitore c'e'.</h1>
  <p>La schermata vera arriva con il blocco che la disegna. Intanto il servitore
     risponde gia': <code>/api/stato</code> dice a che punto e' il progetto,
     <code>/api/modelli</code> chi puo' lavorare, <code>/api/benzina</code> quanta
     quota resta.</p>
</main>
</html>"""


def avvia_servitore(porta, progetto):
    if os.name == "nt" and os.environ.get("METODO_FINESTRA_DEDICATA") == "si":
        # Nato da 'apri', quindi ha una finestra tutta sua: un titolo che dica cosa si
        # spegne con un clic. Alle altre finestre (terminali, prove) non si tocca.
        import ctypes
        ctypes.windll.kernel32.SetConsoleTitleW("Metodo Villa — la schermata del runner")
    servitore = ThreadingHTTPServer(("127.0.0.1", porta), Servitore)
    servitore.progetto = progetto
    servitore.corsa = Corsa()
    print("La schermata del runner e' su http://127.0.0.1:%d" % servitore.server_port)
    print("Progetto: %s" % progetto)
    print("Per chiudere: Ctrl+C. (Chiudere questo servitore non ferma una corsa gia' partita.)")
    try:
        servitore.serve_forever()
    except KeyboardInterrupt:
        print("\nChiuso.")
    finally:
        servitore.server_close()
    return 0


def main(argomenti):
    if argomenti and argomenti[0] == "apri":
        return apri_schermata(argomenti[1:])
    if argomenti and argomenti[0] == "comando":
        try:
            grezze = json.load(sys.stdin) if not sys.stdin.isatty() else {}
            impostazioni = convalida(grezze)
        except ValueError:
            print("Le impostazioni non si leggono: mi aspetto un oggetto JSON.", file=sys.stderr)
            return 1
        except ImpostazioneNonValida as e:
            print(str(e), file=sys.stderr)
            return 1
        runner = os.path.join(RADICE_METODO, "metodo", "metodo-villa-runner.sh")
        for pezzo in costruisci_comando(impostazioni, runner, trova_bash() or "bash"):
            print(pezzo)
        return 0

    porta, progetto = PORTA_DI_CASA, RADICE_METODO
    i = 0
    while i < len(argomenti):
        if argomenti[i] == "--porta" and i + 1 < len(argomenti):
            porta = int(argomenti[i + 1]); i += 2
        elif argomenti[i] == "--cartella" and i + 1 < len(argomenti):
            progetto = os.path.abspath(argomenti[i + 1]); i += 2
        else:
            print("Uso: servitore-gui.py [--porta N] [--cartella DIR] | comando < impostazioni.json "
                  "| apri [--porta N] [--cartella DIR] [--senza-browser]", file=sys.stderr)
            return 1
    try:
        return avvia_servitore(porta, progetto)
    except OSError as e:
        print("Non riesco ad ascoltare sulla porta %d: %s\n"
              "Forse la schermata e' gia' aperta. Chiudila, oppure scegline un'altra "
              "con --porta." % (porta, e), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

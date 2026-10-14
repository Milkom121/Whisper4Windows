#!/usr/bin/env bash
# metodo-sync.sh — sincronizza il Metodo Villa tra il repo madre e questo progetto, nei DUE sensi.
#
# Disegno completo: docs/fondamenta/sistema-aggiornamento-metodo.md
#
# COMANDI
#   scarica [percorso-madre]     Porta gli aggiornamenti del Metodo dalla madre in questo progetto.
#   rimanda [--tutti|file...]    Propone alla madre le migliorie al Metodo nate in questo progetto.
#                                Senza argomenti = anteprima (mostra i candidati, non tocca nulla).
#   converti-claude              Spezza un CLAUDE.md misto in: file operativo (Metodo) + CLAUDE.md magro.
#   stato [percorso-madre]       Mostra che cosa differisce tra progetto e madre (sola lettura).
#   nuovo-progetto [--forza]     Toglie i documenti di lavoro che il progetto ha ereditato dal
#                                Metodo (roadmap, promemoria, registri) e ci mette i modelli vuoti.
#                                Si lancia UNA volta, appena creato il progetto. Si rifiuta di
#                                partire se il progetto e' gia' avviato.
#
# La madre si indica con: argomento -> variabile METODO_VILLA_HOME -> default noto.
#
# PRINCIPI (vedi documento): scarico leggero e reversibile; rimando sorvegliato (ramo + proposta che
# approva Villa); confronti che ignorano i fine-riga; mai sovrascrivere lavoro non salvato.

set -euo pipefail

# ---------------------------------------------------------------------------
# Costanti e contesto
# ---------------------------------------------------------------------------
DEFAULT_MADRE="C:/Users/Mario/Documents/GitHub/Metodo-Villa-v2"
MARCATORE="--- REGOLE SPECIFICHE PROGETTO ---"
FILE_OPERATIVO=".claude/metodo-villa/00-CLAUDE-OPERATIVO.md"

PROGETTO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$PROGETTO" ]; then
  echo "ERRORE: non sei dentro un repository git." >&2
  exit 1
fi
NOME_PROGETTO="$(basename "$PROGETTO")"

# ---------------------------------------------------------------------------
# Helper generici
# ---------------------------------------------------------------------------

# Risolve e valida il percorso del repo madre.
risolvi_madre() {
  local m="${1:-${METODO_VILLA_HOME:-$DEFAULT_MADRE}}"
  if [ ! -d "$m" ]; then
    echo "ERRORE: repo madre non trovato: $m" >&2
    echo "Passa il percorso come argomento o imposta METODO_VILLA_HOME." >&2
    exit 1
  fi
  (cd "$m" && pwd)
}

# Taglia commenti, spazi iniziali/finali da una riga.
pulisci_riga() {
  local s="${1%%#*}"
  s="${s#"${s%%[![:space:]]*}"}"   # trim sinistra
  s="${s%"${s##*[![:space:]]}"}"   # trim destra
  printf '%s' "$s"
}

# Legge il manifest dalla madre. Emette righe "tipo|flag|path":
#   tipo = dir|file ; flag = div|"" ; path = percorso relativo (senza "/" finale).
leggi_manifest() {
  local madre="$1"
  local mf="$madre/metodo/metodo-manifest.txt"
  local raw line flag
  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(pulisci_riga "$raw")"
    [ -z "$line" ] && continue
    flag=""
    # "!div" a fine riga, preceduto da uno o piu' spazi/tab.
    if [[ "$line" =~ ^(.+)[[:space:]]+!div$ ]]; then
      line="${BASH_REMATCH[1]}"; flag="div"
    fi
    if [ "${line%/}" != "$line" ]; then
      printf 'dir|%s|%s\n' "$flag" "${line%/}"
    else
      printf 'file|%s|%s\n' "$flag" "$line"
    fi
  done < "$mf"
}

# Legge la lista degli spostamenti dalla madre. Emette righe "tipo|vecchio|nuovo"
# con i campi gia' ripuliti dagli spazi. Vedi metodo/metodo-spostamenti.txt.
leggi_spostamenti() {
  local madre="$1"
  local sf="$madre/metodo/metodo-spostamenti.txt"
  [ -f "$sf" ] || return 0
  local raw line tipo vecchio nuovo
  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(pulisci_riga "$raw")"
    [ -z "$line" ] && continue
    IFS='|' read -r tipo vecchio nuovo <<< "$line"
    tipo="$(pulisci_riga "${tipo:-}")"
    vecchio="$(pulisci_riga "${vecchio:-}")"
    nuovo="$(pulisci_riga "${nuovo:-}")"
    if [ -z "$tipo" ] || [ -z "$vecchio" ]; then continue; fi
    printf '%s|%s|%s\n' "$tipo" "$vecchio" "$nuovo"
  done < "$sf"
}

# Applica gli spostamenti dichiarati dalla madre, cosi' un progetto nato prima di
# un riordino si riallinea da solo invece di accumulare doppioni.
# Garanzie: i file "impalcatura" si spostano e MAI si cancellano; i file "metodo"
# si rimuovono solo DOPO aver verificato che la copia nuova e' davvero arrivata.
applica_spostamenti() {
  local madre="$1"
  local fatti="" dubbi="" tipo vecchio nuovo vsrc ndst genitore
  while IFS='|' read -r tipo vecchio nuovo; do
    [ -z "$vecchio" ] && continue
    if e_escluso "$vecchio"; then
      fatti="$fatti  - saltato (eccezione del progetto): $vecchio"$'\n'
      continue
    fi
    vsrc="$PROGETTO/$vecchio"
    [ -e "$vsrc" ] || continue          # gia' riordinato: niente da fare

    case "$tipo" in
      metodo)
        # Rete di sicurezza: non rimuovo il vecchio se il nuovo non c'e' davvero
        # (copia fallita), altrimenti resterebbe un progetto senza quel pezzo.
        if [ "$nuovo" != "-" ] && [ ! -e "$PROGETTO/$nuovo" ]; then
          dubbi="$dubbi  ! $vecchio NON rimosso: la copia nuova ($nuovo) non risulta arrivata."$'\n'
          continue
        fi
        if rm -rf "$vsrc"; then
          if [ "$nuovo" = "-" ]; then
            fatti="$fatti  - rimosso (non fa piu' parte del Metodo): $vecchio"$'\n'
          else
            fatti="$fatti  - rimosso (ora sta in $nuovo): $vecchio"$'\n'
          fi
        else
          dubbi="$dubbi  ! non riesco a rimuovere: $vecchio"$'\n'
        fi
        ;;
      impalcatura)
        if [ "$nuovo" = "-" ]; then
          dubbi="$dubbi  ! $vecchio dichiarato senza destinazione: non lo tocco (i file di lavoro non si cancellano)."$'\n'
          continue
        fi
        ndst="$PROGETTO/$nuovo"
        if [ -e "$ndst" ]; then
          dubbi="$dubbi  ! esistono ENTRAMBI $vecchio e $nuovo: non indovino quale vale, decidi tu."$'\n'
          continue
        fi
        mkdir -p "$(dirname "$ndst")"
        if mv "$vsrc" "$ndst"; then
          fatti="$fatti  > spostato: $vecchio  ->  $nuovo"$'\n'
        else
          dubbi="$dubbi  ! non riesco a spostare: $vecchio"$'\n'
        fi
        ;;
      *)
        dubbi="$dubbi  ! tipo di spostamento sconosciuto ($tipo), salto: $vecchio"$'\n'
        ;;
    esac

    # Se la cartella di partenza e' rimasta vuota, la tolgo (solo se vuota).
    genitore="$(dirname "$vsrc")"
    if [ "$genitore" != "$PROGETTO" ] && [ -d "$genitore" ]; then
      rmdir "$genitore" 2>/dev/null && fatti="$fatti  - rimossa cartella vuota: $(dirname "$vecchio")"$'\n'
    fi
  done < <(leggi_spostamenti "$madre")

  if [ -n "$fatti" ]; then
    echo
    echo "RIORDINO (il Metodo ha spostato dei file: allineo il progetto)"
    printf '%s' "$fatti"
  fi
  if [ -n "$dubbi" ]; then
    echo
    echo "RIORDINO — da guardare (non ho deciso da solo):" >&2
    printf '%s' "$dubbi" >&2
  fi
}

# Segnala i documenti rimasti sciolti in docs/ dopo il riordino: sono del
# progetto, quindi li smista Villa (non si indovina fondamenta vs diario).
segnala_docs_sciolti() {
  [ -d "$PROGETTO/docs" ] || return 0
  local sciolti=""
  local f n
  while IFS= read -r f; do
    n="$(basename "$f")"
    sciolti="$sciolti  ? docs/$n"$'\n'
  done < <(find "$PROGETTO/docs" -maxdepth 1 -type f 2>/dev/null | sort)
  [ -z "$sciolti" ] && return 0
  echo
  echo "Documenti ancora sciolti in docs/ — sono TUOI, decidi tu dove vanno:"
  echo "  fondamenta/ = scritti una volta e poi consultati (concept, requisiti, schema)"
  echo "  diario/     = crescono lavorando (handoff, log, decisioni, collaudi)"
  printf '%s' "$sciolti"
}

# Stampa i pattern di eccezione del progetto (.metodo-sync-ignore), uno per riga.
leggi_eccezioni() {
  local f="$PROGETTO/.metodo-sync-ignore"
  [ -f "$f" ] || return 0
  local raw line
  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(pulisci_riga "$raw")"
    [ -n "$line" ] && printf '%s\n' "$line"
  done < "$f"
}

# Vero (0) se il path relativo $1 e' coperto da una eccezione del progetto.
e_escluso() {
  local path="$1" pat
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    [ "$path" = "$pat" ] && return 0                 # match letterale esatto (path con [ ] ? *)
    case "$path" in $pat) return 0 ;; esac           # match glob (nota: * attraversa anche le /)
    case "$path" in "${pat%/}"/*) return 0 ;; esac   # eccezione-cartella: tutto cio' che sta sotto
  done < <(leggi_eccezioni)
  return 1
}

# Confronta due file ignorando i fine-riga (CR). 0 = identici, 1 = diversi o mancanti.
identici_ignora_cr() {
  local a="$1" b="$2"
  [ -f "$a" ] && [ -f "$b" ] || return 1
  diff -q <(tr -d '\r' < "$a") <(tr -d '\r' < "$b") >/dev/null 2>&1
}

# Elenca i file (path relativi al progetto) che differiscono dentro una cartella di lista bianca.
# Considera l'unione dei file presenti nella madre e nel progetto: cosi' coglie anche i mancanti.
file_diversi_in_dir() {
  local madre="$1" rel="$2"
  local sdir="$madre/$rel" ddir="$PROGETTO/$rel" f
  { [ -d "$sdir" ] && ( cd "$sdir" && find . -type f ) ; \
    [ -d "$ddir" ] && ( cd "$ddir" && find . -type f ) ; } \
    | sed 's#^\./##' | sort -u | while IFS= read -r f; do
        [ -z "$f" ] && continue
        e_escluso "$rel/$f" && continue
        identici_ignora_cr "$sdir/$f" "$ddir/$f" || printf '%s/%s\n' "$rel" "$f"
      done
}

# Come sopra, ma per il RIMANDO: parte dai soli file presenti nel PROGETTO (quelli che la madre
# non ha o che differiscono). Un file presente solo nella madre NON e' da rimandare: e' da scaricare.
file_da_rimandare_in_dir() {
  local madre="$1" rel="$2"
  local ddir="$PROGETTO/$rel" f
  [ -d "$ddir" ] || return 0
  ( cd "$ddir" && find . -type f ) | sed 's#^\./##' | while IFS= read -r f; do
    [ -z "$f" ] && continue
    e_escluso "$rel/$f" && continue
    identici_ignora_cr "$madre/$rel/$f" "$ddir/$f" || printf '%s/%s\n' "$rel" "$f"
  done
}

# Elenca i file presenti nel PROGETTO sotto $rel ma NON nella madre: orfani del Metodo
# (rimossi/rinominati nella madre) oppure skill di dominio del progetto non dichiarate.
file_solo_progetto_in_dir() {
  local madre="$1" rel="$2"
  local sdir="$madre/$rel" ddir="$PROGETTO/$rel" f
  [ -d "$ddir" ] || return 0
  ( cd "$ddir" && find . -type f ) | sed 's#^\./##' | while IFS= read -r f; do
    [ -z "$f" ] && continue
    e_escluso "$rel/$f" && continue
    [ -f "$sdir/$f" ] || printf '%s/%s\n' "$rel" "$f"
  done
}

# Verifica che le eccezioni non spazzino via l'intero Metodo (errore di battitura pericoloso).
valida_eccezioni() {
  local madre="$1" pat tot=0 esclusi=0 tipo flag path
  while IFS= read -r pat; do
    case "$pat" in "*"|"**"|"/"|".")
      echo "STOP: l'eccezione '$pat' in .metodo-sync-ignore escluderebbe tutto il Metodo." >&2
      exit 1 ;;
    esac
  done < <(leggi_eccezioni)
  while IFS='|' read -r tipo flag path; do
    [ -z "$path" ] && continue
    tot=$((tot+1)); e_escluso "$path" && esclusi=$((esclusi+1))
  done < <(leggi_manifest "$madre")
  if [ "$tot" -gt 0 ] && [ "$esclusi" -ge "$tot" ]; then
    echo "STOP: le eccezioni escluderebbero TUTTE le voci del Metodo. Controlla .metodo-sync-ignore." >&2
    exit 1
  fi
}

# Vero (0) se ci sono modifiche non salvate sui file della lista bianca (stampa i nomi).
sporco_su_whitelist() {
  local madre="$1" sporchi="" tipo flag path
  while IFS='|' read -r tipo flag path; do
    [ -z "$path" ] && continue
    # pathspec esatto + -z: niente regex/quoting; per le cartelle git filtra i discendenti.
    if [ -n "$(git -C "$PROGETTO" status --porcelain -z -- "$path" 2>/dev/null)" ]; then
      sporchi="$sporchi $path"
    fi
  done < <(leggi_manifest "$madre")
  [ -n "$sporchi" ] && { printf '%s' "$sporchi"; return 0; }
  return 1
}

# Controlla che il manifest esista nella madre, altrimenti ferma.
assicura_manifest() {
  local madre="$1"
  if [ ! -f "$madre/metodo/metodo-manifest.txt" ]; then
    echo "ERRORE: manifest non trovato nella madre: $madre/metodo/metodo-manifest.txt" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Comando: scarica (madre -> progetto)
# ---------------------------------------------------------------------------
cmd_scarica() {
  local madre; madre="$(risolvi_madre "${1:-}")"
  assicura_manifest "$madre"
  echo "SCARICO Metodo"
  echo "  da : $madre"
  echo "  a  : $PROGETTO"
  # Da QUALE ramo si copia. Non e' un dettaglio: lo scarico prende i file come stanno nella
  # cartella della madre, cioe' sul ramo che li' e' in checkout in questo momento. Se la
  # madre e' in mezzo a un lavoro, il progetto si porta a casa quel lavoro senza saperlo.
  local _ramo; _ramo="$(git -C "$madre" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"
  echo "  ramo della madre: $_ramo"
  case "$_ramo" in
    main|master|develop|"?") ;;
    *) echo "  ATTENZIONE: la madre non e' sul ramo stabile. Stai per prendere il Metodo"
       echo "              cosi' com'e' su '$_ramo' — lavoro in corso, non ancora approvato."
       echo "              Se non e' quello che vuoi: nella madre torna su main e rilancia.";;
  esac
  echo

  valida_eccezioni "$madre"

  # Sicurezza: non sovrascrivere lavoro non salvato sui file del Metodo.
  local sporchi
  if sporchi="$(sporco_su_whitelist "$madre")"; then
    echo "STOP: ci sono modifiche non salvate su file del Metodo:" >&2
    echo "   $sporchi" >&2
    echo "Committa o stasha prima di scaricare, cosi' nulla va perso." >&2
    exit 1
  fi

  local tipo flag path src dst
  while IFS='|' read -r tipo flag path; do
    [ -z "$path" ] && continue
    if e_escluso "$path"; then echo "  - saltato (eccezione): $path"; continue; fi
    src="$madre/$path"; dst="$PROGETTO/$path"
    if [ ! -e "$src" ]; then echo "  ! assente nella madre, salto: $path"; continue; fi
    if [ "$tipo" = "dir" ]; then
      mkdir -p "$dst"; cp -r "$src/." "$dst/"; echo "  + cartella: $path"
    else
      # avviso: file gia' presente e diverso = possibile personalizzazione non dichiarata
      if [ -f "$dst" ] && ! identici_ignora_cr "$src" "$dst"; then
        echo "  ~ ATTENZIONE: $path era diverso dalla madre, lo sovrascrivo (era una tua modifica non dichiarata?)"
      fi
      mkdir -p "$(dirname "$dst")"
      # copia atomica (tmp + rename): sicura anche quando lo scarico aggiorna SE STESSO.
      # if/else esplicito: NON dichiarare successo se cp fallisce; salta il file e prosegui.
      if cp "$src" "$dst.tmp.$$" 2>/dev/null && mv -f "$dst.tmp.$$" "$dst"; then
        echo "  + file: $path"
      else
        rm -f "$dst.tmp.$$" 2>/dev/null || true
        echo "  ! ERRORE copia, salto (non aggiornato): $path" >&2
      fi
    fi
  done < <(leggi_manifest "$madre")

  # Riordino: DOPO la copia (le destinazioni nuove ci sono gia'), togli i residui
  # nei posti vecchi e sposta l'impalcatura di lavoro. Vedi metodo-spostamenti.txt.
  applica_spostamenti "$madre"
  segnala_docs_sciolti

  # Segnala i file presenti SOLO nel progetto (orfani del Metodo rimossi dalla madre,
  # oppure skill di dominio non ancora dichiarate in .metodo-sync-ignore). NON si cancellano.
  local _orf="" _tt _tf _tp _of
  while IFS='|' read -r _tt _tf _tp; do
    [ "$_tt" = "dir" ] || continue
    e_escluso "$_tp" && continue
    while IFS= read -r _of; do
      [ -n "$_of" ] && _orf="$_orf  ? $_of"$'\n'
    done < <(file_solo_progetto_in_dir "$madre" "$_tp")
  done < <(leggi_manifest "$madre")
  if [ -n "$_orf" ]; then
    echo
    echo "Presenti SOLO nel progetto (orfani del Metodo o skill di dominio da dichiarare): NON cancellati."
    printf '%s' "$_orf"
  fi

  # I ganci del Metodo (cap. 25) hanno una gamba nelle impostazioni del progetto, che NON si
  # possono sovrascrivere: sono sue. Quindi non si copia il file, si innesta la voce che
  # manca. Idempotente: se c'e' gia', non fa niente.
  if [ -f "$madre/metodo/innesta-ganci.py" ] && command -v python >/dev/null 2>&1; then
    echo
    python "$madre/metodo/innesta-ganci.py" "$PROGETTO" || true
  fi

  # Il profilo personale di Villa (personale/ nella madre) non e' del progetto e non sta nel
  # manifest: vive in ~/.claude/ e si carica in OGNI sessione, ovunque. Si allinea qui perche'
  # questo e' il momento in cui Villa dice "allineami al Metodo", e cosi' non c'e' niente da
  # ricordarsi. L'allineamento non sovrascrive mai una copia piu' recente: avvisa e si ferma.
  if [ -f "$madre/metodo/metodo-profilo.sh" ] && [ -d "$madre/personale" ]; then
    echo
    bash "$madre/metodo/metodo-profilo.sh" allinea "$madre" || true
  fi

  echo
  echo "Fatto. NULLA e' stato committato: rivedi con   git status   e   git diff   e decidi tu cosa tenere."
}

# ---------------------------------------------------------------------------
# Comando: nuovo-progetto — togli di dosso i panni del Metodo
# ---------------------------------------------------------------------------
# PERCHE' SERVE. Il repository del Metodo fa due mestieri: e' il Metodo, ed e'
# anche lo stampo da cui nascono i progetti. Quindi un progetto appena creato si
# porta dietro non solo gli attrezzi (giusto) ma anche i DOCUMENTI DI LAVORO del
# Metodo: il suo piano, il suo promemoria, il suo registro delle decisioni.
# Il risultato e' un progetto che indossa i panni di un altro, con una roadmap
# gia' "completata" che il runner legge e non sa che farsene.
#
# Questo comando mette al loro posto i modelli vuoti di metodo/modelli/.
# Si lancia UNA VOLTA, appena creato il progetto.
cmd_nuovo_progetto() {
  local madre; madre="$(risolvi_madre "${1:-}")"
  local forza="no"
  [ "${1:-}" = "--forza" ] || [ "${2:-}" = "--forza" ] && forza="si"
  local modelli="$madre/metodo/modelli"
  if [ ! -d "$modelli" ]; then
    echo "ERRORE: modelli non trovati nella madre: $modelli" >&2; exit 1
  fi

  # Rete di sicurezza: non si azzera mai lavoro VERO.
  #
  # Il segnale giusto non e' "ci sono blocchi spuntati": la roadmap ereditata dal
  # Metodo ne ha decine, ed e' esattamente quella che siamo qui a togliere. Il
  # segnale giusto e' "la roadmap e' ANCORA quella della madre": se lo e', e'
  # roba ereditata; se e' diversa, qualcuno ci ha lavorato e non si tocca.
  if [ "$forza" = "no" ]; then
    local ereditata="no"
    if [ -f "$PROGETTO/ROADMAP.md" ] && [ -f "$madre/ROADMAP.md" ]; then
      identici_ignora_cr "$madre/ROADMAP.md" "$PROGETTO/ROADMAP.md" && ereditata="si"
    fi
    if [ "$ereditata" = "no" ]; then
      local fatti=0 stato=""
      [ -f "$PROGETTO/ROADMAP.md" ] && fatti="$(grep -c '^\- \[x\]' "$PROGETTO/ROADMAP.md" 2>/dev/null || echo 0)"
      [ -f "$PROGETTO/docs/diario/progress.json" ] && stato="$(grep -o '"status"[^,]*' "$PROGETTO/docs/diario/progress.json" 2>/dev/null || true)"
      if [ "${fatti:-0}" -gt 0 ] || { [ -n "$stato" ] && ! echo "$stato" | grep -q "NOT_STARTED"; }; then
        echo "STOP: la roadmap di questo progetto NON e' quella ereditata dal Metodo," >&2
        echo "quindi qualcuno ci ha gia' lavorato." >&2
        echo "   blocchi gia' fatti: ${fatti:-0}" >&2
        echo "   stato del runner  : ${stato:-sconosciuto}" >&2
        echo "Azzerare adesso vorrebbe dire buttare via lavoro vero." >&2
        echo "Se sai quello che fai: aggiungi --forza." >&2
        exit 1
      fi
    fi
  fi

  echo "PROGETTO NUOVO — tolgo i documenti di lavoro ereditati dal Metodo"
  echo "  modelli da: $modelli"
  echo

  local nome dst
  for nome in ROADMAP.md; do
    dst="$PROGETTO/$nome"
    cp "$modelli/$nome" "$dst" && echo "  ~ azzerato: $nome"
  done
  mkdir -p "$PROGETTO/docs/diario" "$PROGETTO/docs/fondamenta"
  for nome in handoff.md progress.json ideas.md decisions.md decisioni-da-rivedere.md dev-shortcuts.md; do
    [ -f "$modelli/$nome" ] || continue
    cp "$modelli/$nome" "$PROGETTO/docs/diario/$nome" && echo "  ~ azzerato: docs/diario/$nome"
  done

  # I documenti di PROGETTAZIONE del Metodo non sono del progetto: si segnalano
  # e si spostano da parte, non si cancellano (potrebbero servire da riferimento).
  local avanzi="" f n
  for f in "$PROGETTO"/docs/*.md "$PROGETTO"/docs/fondamenta/*.md; do
    [ -f "$f" ] || continue
    n="$(basename "$f")"
    if [ -f "$madre/docs/fondamenta/$n" ] || [ -f "$madre/docs/$n" ]; then
      mkdir -p "$PROGETTO/docs/del-metodo"
      mv "$f" "$PROGETTO/docs/del-metodo/$n" && avanzi="$avanzi  > spostato in docs/del-metodo/: $n"$'\n'
    fi
  done
  if [ -n "$avanzi" ]; then
    echo
    echo "Documenti di progettazione del METODO, non di questo progetto:"
    printf '%s' "$avanzi"
    echo "  (spostati, non cancellati: se non ti servono butta pure la cartella)"
  fi

  echo
  echo "Fatto. NULLA e' stato committato: guarda con   git status   e decidi tu."
  echo "Adesso il progetto e' una scatola pulita. Il passo dopo e' la discovery:"
  echo "raccontare a Claude cos'e' il progetto, e da li' nascono PROJECT_CONFIG.md"
  echo "e la roadmap vera."
}

# ---------------------------------------------------------------------------
# Comando: stato (sola lettura)
# ---------------------------------------------------------------------------
cmd_stato() {
  local madre; madre="$(risolvi_madre "${1:-}")"
  assicura_manifest "$madre"
  echo "STATO Metodo (progetto vs madre: $madre) — fine-riga ignorati"
  echo
  local tipo flag path n=0 diff_file
  while IFS='|' read -r tipo flag path; do
    [ -z "$path" ] && continue
    if e_escluso "$path"; then echo "  - escluso: $path"; continue; fi
    if [ "$tipo" = "dir" ]; then
      while IFS= read -r diff_file; do
        [ -z "$diff_file" ] && continue
        echo "  diverso: $diff_file"; n=$((n+1))
      done < <(file_diversi_in_dir "$madre" "$path")
    else
      local src="$madre/$path" dst="$PROGETTO/$path"
      if   [ ! -e "$src" ] && [ ! -e "$dst" ]; then :   # da nessuna parte: niente da fare
      elif [ ! -e "$dst" ]; then echo "  da scaricare (manca nel progetto): $path"; n=$((n+1))
      elif [ ! -e "$src" ]; then echo "  solo nel progetto (candidato rimando): $path"; n=$((n+1))
      elif ! identici_ignora_cr "$src" "$dst"; then echo "  diverso: $path"; n=$((n+1))
      fi
    fi
  done < <(leggi_manifest "$madre")
  echo
  echo "$n elemento/i differiscono."
}

# Costruisce l'elenco completo dei file di lista bianca che differiscono (espande le cartelle).
# Emette un path per riga. Usato dal rimando.
candidati_rimando() {
  local madre="$1" tipo flag path diff_file
  while IFS='|' read -r tipo flag path; do
    [ -z "$path" ] && continue
    e_escluso "$path" && continue
    if [ "$tipo" = "dir" ]; then
      file_da_rimandare_in_dir "$madre" "$path"
    else
      [ -e "$PROGETTO/$path" ] || continue   # non c'e' nel progetto: niente da rimandare
      identici_ignora_cr "$madre/$path" "$PROGETTO/$path" || printf '%s\n' "$path"
    fi
  done < <(leggi_manifest "$madre")
}

# Vero (0) se il path (file singolo) e' marcato !div nel manifest.
e_divergente() {
  local madre="$1" path="$2" tipo flag mpath
  while IFS='|' read -r tipo flag mpath; do
    [ "$mpath" = "$path" ] && [ "$flag" = "div" ] && return 0
  done < <(leggi_manifest "$madre")
  return 1
}

# Ramo base della madre: origin/HEAD -> main -> develop -> "main".
ramo_base_madre() {
  local madre="$1" b
  b="$(git -C "$madre" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
  [ -n "$b" ] && { echo "$b"; return; }
  git -C "$madre" show-ref --verify --quiet refs/heads/main    && { echo "main"; return; }
  git -C "$madre" show-ref --verify --quiet refs/heads/develop && { echo "develop"; return; }
  echo "main"
}

# ---------------------------------------------------------------------------
# Comando: rimanda (progetto -> madre), come proposta su ramo
# ---------------------------------------------------------------------------
cmd_rimanda() {
  local madre; madre="$(risolvi_madre "")"
  assicura_manifest "$madre"
  valida_eccezioni "$madre"

  # Raccolgo i candidati (file Metodo che differiscono, fine-riga ignorati).
  local lista; lista="$(candidati_rimando "$madre" || true)"
  if [ -z "$lista" ]; then
    echo "Niente da rimandare: il Metodo di questo progetto coincide con la madre."
    return 0
  fi

  echo "CANDIDATI al rimando (file Metodo che hai cambiato rispetto alla madre):"
  echo "$lista" | sed 's/^/  - /'
  echo
  echo "Promemoria: se la madre potrebbe essere piu' avanti, lancia prima 'scarica' per non"
  echo "sovrascrivere migliorie altrui (vedi disegno: 'scarica prima di rimandare')."
  echo

  # Senza argomenti = anteprima: mostro i diff e mi fermo.
  if [ "$#" -eq 0 ]; then
    echo "--- ANTEPRIMA (nessuna modifica inviata). Diff progetto vs madre: ---"
    local f
    echo "$lista" | while IFS= read -r f; do
      [ -z "$f" ] && continue
      echo; echo "### $f"
      diff <(tr -d '\r' < "$madre/$f" 2>/dev/null) <(tr -d '\r' < "$PROGETTO/$f" 2>/dev/null) || true
    done
    echo
    echo "Per inviare davvero:  metodo-sync.sh rimanda --tutti   (oppure elenca i file)."
    echo "Per i file ad alto rischio (runner) aggiungi  --conferma-divergenti."
    return 0
  fi

  # Selezione: --tutti, oppure lista esplicita di file; flag per i divergenti.
  local conferma_div=0 selezione=() a
  for a in "$@"; do
    case "$a" in
      --tutti) while IFS= read -r f; do [ -n "$f" ] && selezione+=("$f"); done < <(printf '%s\n' "$lista") ;;
      --conferma-divergenti) conferma_div=1 ;;
      *) selezione+=("$a") ;;
    esac
  done

  # Filtra i divergenti se non confermati esplicitamente.
  local finali=() s
  for s in "${selezione[@]:-}"; do
    [ -z "$s" ] && continue
    if e_divergente "$madre" "$s" && [ "$conferma_div" -eq 0 ]; then
      echo "  ! salto '$s' (alto rischio divergenza): aggiungi --conferma-divergenti per includerlo."
      continue
    fi
    finali+=("$s")
  done
  if [ "${#finali[@]}" -eq 0 ]; then
    echo "Nessun file selezionato da inviare."; return 0
  fi

  # La madre deve avere l'area di lavoro pulita.
  if [ -n "$(git -C "$madre" status --porcelain || true)" ]; then
    echo "STOP: il repo madre ha modifiche non salvate. Sistemalo prima (la madre dev'essere pulita)." >&2
    exit 1
  fi

  local base ramo data orig_branch
  base="$(ramo_base_madre "$madre")"
  data="$(date +%Y-%m-%d-%H%M%S)"                                  # timestamp completo: rami univoci
  ramo="rientro/da-${NOME_PROGETTO}-${data}"
  orig_branch="$(git -C "$madre" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "$base")"

  # Il ramo non deve gia' esistere (evita di sovrascrivere lavoro con checkout -B).
  if git -C "$madre" show-ref --verify --quiet "refs/heads/$ramo"; then
    echo "STOP: il ramo $ramo esiste gia' nella madre. Riprova tra un istante." >&2
    exit 1
  fi

  echo
  echo "Preparo la proposta nella madre:"
  echo "  base: $base   ramo: $ramo"

  git -C "$madre" fetch --quiet origin "$base" 2>/dev/null || true
  if ! git -C "$madre" checkout --quiet "$base" 2>/dev/null; then
    echo "STOP: non riesco a posizionarmi sul ramo base '$base' della madre." >&2; exit 1
  fi
  # Se la base non e' allineabile in fast-forward, avviso ma procedo sulla base locale.
  git -C "$madre" pull --quiet --ff-only origin "$base" 2>/dev/null \
    || echo "  (nota: base '$base' non aggiornata dall'origin in fast-forward; procedo sulla locale)"
  git -C "$madre" checkout --quiet -b "$ramo"

  # Rete di sicurezza: se qualcosa va storto da qui, riporto la madre al ramo originale e pulisco.
  ripristina_madre() {
    git -C "$madre" reset --quiet --hard 2>/dev/null || true
    git -C "$madre" checkout --quiet "$orig_branch" 2>/dev/null || true
    git -C "$madre" branch -D "$ramo" 2>/dev/null || true
  }

  # Copio i file scelti dal progetto nella madre.
  for s in "${finali[@]}"; do
    mkdir -p "$madre/$(dirname "$s")"
    if ! cp "$PROGETTO/$s" "$madre/$s"; then
      echo "ERRORE copia di $s: ripristino la madre e mi fermo." >&2; ripristina_madre; exit 1
    fi
    git -C "$madre" add -- "$s"
    echo "  + $s"
  done

  if ! git -C "$madre" commit --quiet -m "Rientro Metodo da ${NOME_PROGETTO} (${data})"; then
    echo "ERRORE nel commit della madre: ripristino e mi fermo." >&2; ripristina_madre; exit 1
  fi

  if git -C "$madre" push --quiet -u origin "$ramo" 2>/dev/null; then
    echo "Ramo pubblicato."
    if command -v gh >/dev/null 2>&1; then
      ( cd "$madre" && gh pr create --base "$base" --head "$ramo" \
          --title "Rientro Metodo da ${NOME_PROGETTO} (${data})" \
          --body "Migliorie al Metodo nate in ${NOME_PROGETTO}. File: ${finali[*]}. Rivedere e fondere se ok (decide Villa)." ) \
        && echo "Proposta di fusione (PR) creata." \
        || echo "PR non creata in automatico: aprila a mano dal ramo $ramo."
    else
      echo "gh non disponibile: apri la PR a mano nel repo madre dal ramo $ramo verso $base."
    fi
  else
    echo "ATTENZIONE: push fallito (rete/permessi). Il commit e' sul ramo LOCALE $ramo della madre:"
    echo "  pubblicalo piu' tardi. NON ho ripristinato, cosi' non perdi il lavoro."
  fi

  # Riporto la madre sul ramo originale (il lavoro resta sul ramo $ramo).
  git -C "$madre" checkout --quiet "$orig_branch" 2>/dev/null || true
  echo
  echo "Fatto. La madre e' tornata sul ramo '$orig_branch'. La fusione la decidi tu (Villa)."
}

# ---------------------------------------------------------------------------
# Comando: converti-claude (spezza un CLAUDE.md misto)
# ---------------------------------------------------------------------------
cmd_converti_claude() {
  local cm="$PROGETTO/CLAUDE.md"
  [ -f "$cm" ] || { echo "ERRORE: CLAUDE.md non trovato in $PROGETTO" >&2; exit 1; }

  local bak="$cm.pre-split.bak"
  [ -e "$bak" ] && { echo "ERRORE: esiste gia' $bak — rimuovilo o rinominalo prima." >&2; exit 1; }

  # Il marcatore deve comparire ESATTAMENTE una volta.
  local occ; occ="$(grep -cF -- "$MARCATORE" "$cm" || true)"
  if [ "$occ" != "1" ]; then
    echo "STOP: marcatore '$MARCATORE' trovato $occ volte (atteso: 1)." >&2
    echo "Caso anomalo: NON converto da solo per non perdere le tue regole. Serve l'occhio di Villa." >&2
    exit 1
  fi

  cp "$cm" "$bak"
  echo "Backup salvato: $bak"

  # Estraggo la parte DAL marcatore in poi (le regole del progetto).
  local regole; regole="$(awk -v m="$MARCATORE" 'f{print} index($0,m){f=1}' "$cm")"

  # Costruisco il nuovo CLAUDE.md magro su file temporaneo, poi rename atomico.
  {
    printf '# CLAUDE.md — %s\n\n' "$NOME_PROGETTO"
    printf '> Le regole operative del Metodo Villa vivono nel file separato qui sotto.\n'
    printf '> LEGGILO SEMPRE a inizio sessione e a ogni invocazione del runner:\n\n'
    printf '@%s\n\n' "$FILE_OPERATIVO"
    printf 'Se per qualsiasi motivo la riga "@" sopra non venisse seguita, apri e leggi a mano:\n'
    printf '%s\n\n' "$FILE_OPERATIVO"
    printf '%s\n' "$MARCATORE"
    printf '%s\n' "$regole"
  } > "$cm.tmp.$$"
  mv -f "$cm.tmp.$$" "$cm"

  # Verifica di non-perdita AFFIDABILE: la parte dal marcatore in poi del nuovo file deve
  # coincidere ESATTAMENTE con le regole estratte. Confronto a blocco (coglie anche i
  # duplicati persi, cosa che un grep riga-per-riga non vede).
  local regole_dopo; regole_dopo="$(awk -v m="$MARCATORE" 'f{print} index($0,m){f=1}' "$cm")"

  echo
  if [ "$regole_dopo" = "$regole" ]; then
    echo "Conversione OK: le regole del progetto sono conservate identiche."
  else
    echo "ATTENZIONE: le regole non coincidono dopo la conversione. Ripristina da $bak e verifica a mano." >&2
  fi
  echo "ATTENZIONE: le righe SOPRA il marcatore erano considerate Metodo (ora in $FILE_OPERATIVO)."
  echo "Se in questo progetto avevi regole-progetto SOPRA il marcatore, sono nel backup: controllale."
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
uso() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

cmd="${1:-}"; shift || true
case "$cmd" in
  scarica)         cmd_scarica "$@" ;;
  rimanda)         cmd_rimanda "$@" ;;
  converti-claude) cmd_converti_claude "$@" ;;
  stato)           cmd_stato "$@" ;;
  nuovo-progetto)  cmd_nuovo_progetto "$@" ;;
  ""|-h|--help|aiuto) uso ;;
  *) echo "Comando sconosciuto: $cmd" >&2; echo; uso; exit 1 ;;
esac

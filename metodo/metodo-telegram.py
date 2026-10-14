"""Motore del canale Telegram a due sensi del Metodo Villa.

Lo chiama sempre metodo-telegram.sh, che gli passa tutto per variabili d'ambiente
(percorsi Windows, apici e caratteri speciali romperebbero l'interpolazione).

Le due garanzie di sicurezza, entrambe necessarie:
  1. LISTA BIANCA — si accettano solo messaggi che arrivano dalla chat dichiarata
     in TELEGRAM_CHAT_ID. Tutto il resto viene scartato in silenzio.
  2. FILTRO TEMPORALE — quando si fa una domanda, si accettano solo messaggi
     ARRIVATI DOPO. Senza questo, un messaggio vecchio rimasto in coda potrebbe
     essere scambiato per la risposta: e' l'errore piu' pericoloso possibile qui,
     perche' farebbe agire il guardiano su una risposta che riguardava altro.
"""
import io
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API = 'https://api.telegram.org/bot'
FILE_API = 'https://api.telegram.org/file/bot'

TOKEN = os.environ.get('TG_TOKEN', '')
CHAT = os.environ.get('TG_CHAT', '')
CARTELLA = os.environ.get('TG_CARTELLA', '.')
# Sezione (topic) del gruppo dedicata a QUESTO progetto. Vuota = chat semplice.
# E' cio' che tiene separati i progetti che condividono lo stesso bot: si scrive
# solo nella propria sezione e si accetta solo cio' che arriva da li'.
TOPIC = os.environ.get('TG_TOPIC', '').strip()

# Quanto si aspetta, dopo il primo messaggio, per raccogliere quelli subito
# successivi: Villa manda spesso un vocale e poi una foto, e vanno letti insieme.
PAUSA_RACCOLTA = 6

# Durata di una singola attesa lunga verso Telegram. Telegram tiene aperta la
# connessione fino a questo limite se non arriva niente: cosi' non si interroga
# a raffica e la risposta arriva subito quando c'e'.
ATTESA_SINGOLA = 25


def chiama(metodo, parametri=None, timeout=40):
    """Chiama l'API di Telegram. Torna il campo 'result', o solleva."""
    dati = json.dumps(parametri or {}).encode('utf-8')
    req = urllib.request.Request(
        API + TOKEN + '/' + metodo,
        data=dati,
        headers={'Content-Type': 'application/json; charset=utf-8'},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        corpo = json.loads(resp.read().decode('utf-8'))
    if not corpo.get('ok'):
        raise RuntimeError('Telegram ha rifiutato %s: %s' % (metodo, corpo.get('description')))
    return corpo.get('result')


# Telegram rifiuta con errore qualunque messaggio oltre i 4096 caratteri, e il
# resoconto di un blocco ci arriva facilmente. Senza questo taglio la notifica
# non parte AFFATTO e il fallimento si vede solo nel log: meglio una notifica
# accorciata che nessuna notifica. (Lezione imparata su Fedorium, mai tornata
# indietro al Metodo fino ad ora.)
LIMITE_TELEGRAM = 4096
# Lo spazio da riservare si MISURA, non si indovina: riservandone a occhio meno
# di quanto la scritta ne occupi, il messaggio usciva di un carattere oltre il
# limite e veniva rifiutato lo stesso — cioe' il taglio non serviva a niente.
CODA_ACCORCIATO = '\n[…messaggio accorciato]'


def accorcia(testo, limite=LIMITE_TELEGRAM):
    if len(testo) <= limite:
        return testo
    taglio = testo[:limite - len(CODA_ACCORCIATO)]
    # Si torna all'ultimo spazio, ma solo se non si butta via meta' del testo:
    # su un blocco senza spazi si taglia netto invece di svuotarlo.
    spazio = taglio.rfind(' ')
    if spazio > limite // 2:
        taglio = taglio[:spazio]
    return taglio.rstrip() + CODA_ACCORCIATO


def manda(testo, silenzioso=False):
    parametri = {
        'chat_id': CHAT,
        'text': accorcia(testo),
        'disable_notification': silenzioso,
    }
    if TOPIC:
        parametri['message_thread_id'] = int(TOPIC)
    return chiama('sendMessage', parametri)


def crea_sezione(nome):
    """Crea la sezione del gruppo dedicata a un progetto. Torna il suo numero.

    Il bot deve essere amministratore del gruppo con il permesso di gestire i
    topic. Si fa UNA volta per progetto: il numero poi va in .env.runner, perche'
    Telegram non offre un modo per rileggere l'elenco delle sezioni.
    """
    esito = chiama('createForumTopic', {'chat_id': CHAT, 'name': nome})
    return esito['message_thread_id']


def leggi_offset(percorso):
    try:
        with open(percorso) as f:
            return int(f.read().strip())
    except Exception:
        return None


def scrivi_offset(percorso, valore):
    try:
        with open(percorso, 'w') as f:
            f.write(str(valore))
    except Exception:
        pass  # l'offset e' un'ottimizzazione: il filtro temporale resta la garanzia


def nome_sicuro(pezzo):
    """Tiene solo lettere, cifre, punto, trattino e underscore.

    Il nome del file lo componiamo con dati che arrivano da Telegram: ripulirlo
    e' cio' che garantisce che non possa mai diventare qualcosa di diverso da un
    nome di file (ne' un percorso, ne' un pezzo di riga di comando).
    """
    return ''.join(c for c in pezzo if c.isalnum() or c in '._-') or 'file'


def scarica_file(file_id, prefisso):
    """Scarica un allegato nella cartella temporanea. Torna il percorso locale."""
    info = chiama('getFile', {'file_id': file_id})
    remoto = info['file_path']
    estensione = nome_sicuro(os.path.splitext(remoto)[1]) or 'bin'
    locale = os.path.join(
        CARTELLA, '%s-%s.%s' % (prefisso, nome_sicuro(file_id[-12:]), estensione.lstrip('.')))
    locale = locale.replace(os.sep, '/')   # percorso omogeneo anche su Windows
    url = FILE_API + TOKEN + '/' + remoto
    with urllib.request.urlopen(url, timeout=120) as risposta, open(locale, 'wb') as uscita:
        uscita.write(risposta.read())
    return locale


def trascrivi(percorso_audio):
    """Trasforma un vocale in testo col trascrittore configurato.

    TG_TRASCRITTORE e' una RIGA DI COMANDO (puo' avere argomenti propri): ci si
    accoda il percorso del file. Passa dalla shell perche' cosi' funziona sia
    "python metodo/trascrivi-vocale.py" sia un singolo eseguibile, su Windows
    come altrove. Il percorso lo generiamo noi in una cartella temporanea con un
    nome ripulito (vedi nome_sicuro): niente di cio' che arriva da Telegram
    finisce nella riga di comando.

    Torna None se non c'e' un trascrittore o se fallisce: il vocale non si perde
    mai in silenzio, chi chiama avvisa Villa di riscrivere.
    """
    comando = os.environ.get('TG_TRASCRITTORE', '').strip()
    if not comando:
        return None
    try:
        esito = subprocess.run(
            '%s "%s"' % (comando, percorso_audio),
            shell=True, capture_output=True, text=True, timeout=600,
            # Senza questo, Python decodifica l'uscita con la codifica locale
            # (su Windows italiano cp1252) e ogni accento diventa spazzatura:
            # ogni accento diventava spazzatura. Il trascrittore scrive UTF-8.
            encoding='utf-8', errors='replace',
        )
        testo = (esito.stdout or '').strip()
        if not testo and esito.stderr:
            print('trascrizione: %s' % esito.stderr.strip()[:300], file=sys.stderr)
        return testo or None
    except Exception as e:
        print('trascrizione fallita: %s' % type(e).__name__, file=sys.stderr)
        return None


def leggi_messaggio(msg):
    """Trasforma un messaggio Telegram nel testo che leggera' il guardiano.

    Le foto non si convertono in testo: si scaricano e se ne cita il percorso,
    perche' l'agente le immagini le guarda davvero.
    """
    pezzi = []
    testo = msg.get('text') or msg.get('caption')
    if testo:
        pezzi.append(testo.strip())

    if 'voice' in msg or 'audio' in msg:
        voce = msg.get('voice') or msg.get('audio')
        percorso = scarica_file(voce['file_id'], 'vocale')
        trascritto = trascrivi(percorso)
        if trascritto:
            pezzi.append(trascritto)
        else:
            pezzi.append('[vocale ricevuto ma non trascrivibile: chiedi a Villa di riscriverlo]')

    if 'photo' in msg:
        # Telegram manda la stessa foto in piu' misure: l'ultima e' la piu' grande.
        percorso = scarica_file(msg['photo'][-1]['file_id'], 'foto')
        pezzi.append('[immagine da guardare: %s]' % percorso)

    doc = msg.get('document')
    if doc and str(doc.get('mime_type', '')).startswith('image/'):
        percorso = scarica_file(doc['file_id'], 'immagine')
        pezzi.append('[immagine da guardare: %s]' % percorso)

    return '\n'.join(p for p in pezzi if p)


def aspetta_risposta(non_prima_di, attesa_max, file_offset):
    """Attende messaggi di Villa. Torna il testo composto, o None se scade il tempo."""
    offset = leggi_offset(file_offset)
    scadenza = time.time() + attesa_max
    raccolti = []
    chiuso_alle = None

    while time.time() < scadenza:
        if chiuso_alle and time.time() >= chiuso_alle:
            break
        try:
            parametri = {'timeout': ATTESA_SINGOLA, 'allowed_updates': ['message']}
            if offset is not None:
                parametri['offset'] = offset
            aggiornamenti = chiama('getUpdates', parametri, timeout=ATTESA_SINGOLA + 15)
        except Exception as e:
            print('attesa: chiamata fallita (%s), riprovo' % type(e).__name__, file=sys.stderr)
            time.sleep(5)
            continue

        for agg in aggiornamenti:
            offset = agg['update_id'] + 1
            msg = agg.get('message')
            if not msg:
                continue
            # Lista bianca: solo la chat dichiarata.
            if str(msg.get('chat', {}).get('id')) != str(CHAT):
                continue
            # Filtro temporale: solo cio' che e' arrivato DOPO la domanda.
            if msg.get('date', 0) < non_prima_di:
                continue
            # Filtro di sezione: e' cio' che impedisce a due progetti in attesa
            # sullo stesso bot di rubarsi la risposta. Ognuno legge solo la propria.
            if TOPIC and str(msg.get('message_thread_id', '')) != str(TOPIC):
                continue
            letto = leggi_messaggio(msg)
            if letto:
                raccolti.append(letto)
                chiuso_alle = time.time() + PAUSA_RACCOLTA

        scrivi_offset(file_offset, offset if offset is not None else 0)
        if raccolti and chiuso_alle and time.time() >= chiuso_alle:
            break

    return '\n\n'.join(raccolti) if raccolti else None


def comando_chiedi():
    domanda = os.environ.get('TG_MSG', '')
    attesa = int(os.environ.get('TG_ATTESA', '14400'))
    file_offset = os.environ.get('TG_OFFSET_FILE', os.path.join(CARTELLA, 'offset'))

    assicura_sezione()
    inviato = int(time.time())
    manda(domanda)
    risposta = aspetta_risposta(inviato, attesa, file_offset)
    if risposta is None:
        print('Nessuna risposta entro il tempo previsto.', file=sys.stderr)
        return 2
    sys.stdout.write(risposta + '\n')
    return 0


def comando_ascolta():
    attesa = int(os.environ.get('TG_ATTESA', '14400'))
    file_offset = os.environ.get('TG_OFFSET_FILE', os.path.join(CARTELLA, 'offset'))
    # A differenza di "chiedi", qui si guarda anche un po' all'indietro: "ascolta"
    # vuol dire "dammi il prossimo messaggio", e un messaggio arrivato mentre
    # nessuno stava ascoltando non va perso. Il filtro stretto resta su "chiedi",
    # dove serve davvero: li' la risposta deve essere a QUELLA domanda.
    indietro = int(os.environ.get('TG_FINESTRA_INDIETRO', '900'))
    risposta = aspetta_risposta(int(time.time()) - indietro, attesa, file_offset)
    if risposta is None:
        print('Nessun messaggio entro il tempo previsto.', file=sys.stderr)
        return 2
    sys.stdout.write(risposta + '\n')
    return 0


def scrivi_topic_in_env(percorso, numero):
    """Scrive TELEGRAM_TOPIC_ID nel file di configurazione del progetto.

    Se la riga c'e' gia' (vuota, come nel modello) la SOSTITUISCE invece di
    aggiungerne una seconda: due righe per la stessa impostazione funzionano solo
    per caso — vince l'ultima — e chi modificasse la prima non capirebbe perche'
    non cambia niente.

    Se il file non esiste lo CREA: un progetto nuovo prende bot e gruppo dalla
    configurazione condivisa e non ha nessun .env.runner suo, ma il numero della
    sezione e' l'unica cosa che gli appartiene e va scritta da qualche parte.
    """
    if os.path.isfile(percorso):
        with io.open(percorso, encoding='utf-8') as f:
            righe = f.read().split('\n')
    else:
        cartella = os.path.dirname(percorso)
        if cartella and not os.path.isdir(cartella):
            os.makedirs(cartella)
        righe = ['# Configurazione del runner per QUESTO progetto.',
                 '# Bot e gruppo Telegram arrivano dalla configurazione condivisa',
                 '# (~/.metodo-villa/condivisa.env): qui va solo cio che e proprio',
                 '# di questo progetto. Non entra in git: contiene credenziali.',
                 '']
    nuova = 'TELEGRAM_TOPIC_ID=%s' % numero
    sostituita = False
    for i, r in enumerate(righe):
        if r.strip().startswith('TELEGRAM_TOPIC_ID='):
            righe[i] = nuova
            sostituita = True
            break
    if not sostituita:
        righe.append('')
        righe.append('# Sezione del gruppo creata automaticamente per questo progetto')
        righe.append(nuova)
    with io.open(percorso, 'w', encoding='utf-8', newline='') as f:
        f.write('\n'.join(righe))


def assicura_sezione():
    """Fa in modo che questo progetto abbia la SUA sezione nel gruppo.

    Se la sezione non c'e' ancora, la crea col nome del progetto e ne scrive il
    numero in .env.runner, perche' Telegram non permette di rileggere l'elenco
    delle sezioni: se il numero si perde, si creerebbe un doppione a ogni corsa.

    Si applica solo ai gruppi (identificativo negativo). In una chat privata non
    esistono sezioni e non serve fare niente.

    Non e' un passaggio obbligatorio: se qualcosa va storto si prosegue senza
    sezione — il messaggio finisce nel canale generale invece di sparire.
    """
    global TOPIC
    if TOPIC or not CHAT.startswith('-'):
        return
    percorso_env = os.environ.get('TG_ENV_RUNNER', '')
    nome = os.environ.get('TG_NOME_PROGETTO', 'progetto')
    try:
        numero = crea_sezione(nome)
    except Exception as e:
        print('Non riesco a creare la sezione per "%s" (%s). Scrivo nel canale '
              'generale del gruppo. Controlla che il bot sia amministratore con il '
              'permesso di gestire i topic.' % (nome, str(e)[:160]), file=sys.stderr)
        return
    TOPIC = str(numero)
    print('Creata la sezione "%s" nel gruppo (numero %s).' % (nome, numero), file=sys.stderr)
    if not percorso_env:
        print('Aggiungi a mano in .env.runner:  TELEGRAM_TOPIC_ID=%s' % numero, file=sys.stderr)
        return
    try:
        scrivi_topic_in_env(percorso_env, numero)
        print('Numero salvato in %s: non verra' % percorso_env
              + ' ricreata alla prossima corsa.', file=sys.stderr)
    except Exception as e:
        print('Sezione creata ma NON salvata (%s). Mettila a mano in .env.runner, '
              'altrimenti alla prossima corsa se ne crea un altra: '
              'TELEGRAM_TOPIC_ID=%s' % (type(e).__name__, numero), file=sys.stderr)


def comando_manda():
    testo = os.environ.get('TG_MSG', '')
    silenzioso = os.environ.get('TG_SILENT', 'false').lower() == 'true'
    assicura_sezione()
    manda(testo, silenzioso)
    return 0


def comando_stato():
    """Verifica che il token sia valido SENZA mandare messaggi a nessuno."""
    try:
        io_bot = chiama('getMe', {}, timeout=15)
        print('  bot          : @%s (%s)' % (io_bot.get('username'), io_bot.get('first_name')))
        print('  raggiungibile: si')
        return 0
    except Exception as e:
        print('  raggiungibile: NO — %s: %s' % (type(e).__name__, str(e)[:200]), file=sys.stderr)
        return 1


def comando_crea_sezione():
    nome = os.environ.get('TG_MSG', '').strip()
    if not nome:
        print('Serve il nome della sezione.', file=sys.stderr)
        return 1
    try:
        numero = crea_sezione(nome)
    except Exception as e:
        print('Non riesco a creare la sezione: %s' % str(e)[:250], file=sys.stderr)
        print('Controlla che il bot sia AMMINISTRATORE del gruppo con il permesso '
              'di gestire i topic, e che il gruppo abbia gli Argomenti attivi.', file=sys.stderr)
        return 1
    print('Sezione "%s" creata.' % nome)
    print()
    print('Aggiungi questa riga a .env.runner del progetto:')
    print('  TELEGRAM_TOPIC_ID=%s' % numero)
    return 0


def comando_scopri():
    """Elenca le conversazioni e le sezioni che il bot ha visto finora.

    Serve in fase di installazione: dopo aver creato il gruppo e messo il bot
    amministratore, questo comando dice quale numero mettere in TELEGRAM_CHAT_ID
    (e, se hai scritto dentro una sezione, il numero della sezione).

    NON consuma i messaggi: non avanza l'offset, quindi non ruba niente a un
    guardiano che stesse aspettando una risposta.
    """
    try:
        aggiornamenti = chiama('getUpdates', {'timeout': 0, 'limit': 100}, timeout=30)
    except Exception as e:
        print('Non riesco a leggere: %s' % str(e)[:200], file=sys.stderr)
        return 1

    visti = {}
    for agg in aggiornamenti:
        msg = agg.get('message') or agg.get('my_chat_member') or {}
        chat = msg.get('chat') or {}
        if not chat.get('id'):
            continue
        chiave = (chat['id'], msg.get('message_thread_id'))
        if chiave not in visti:
            visti[chiave] = {
                'tipo': chat.get('type', '?'),
                'titolo': chat.get('title') or chat.get('first_name') or '(senza nome)',
                'sezione': (msg.get('reply_to_message') or {}).get('forum_topic_created', {}).get('name'),
            }

    if not visti:
        print('Nessuna conversazione vista di recente.')
        print('Scrivi un messaggio qualsiasi al bot (o nel gruppo, dentro la sezione')
        print('che ti interessa) e rilancia questo comando.')
        return 0

    print('CONVERSAZIONI E SEZIONI VISTE DAL BOT')
    print()
    for (chat_id, thread), info in sorted(visti.items(), key=lambda x: str(x[0])):
        print('  %-14s %s' % (info['tipo'], info['titolo']))
        print('    TELEGRAM_CHAT_ID=%s' % chat_id)
        if thread:
            nome = info['sezione'] or '(sezione)'
            print('    TELEGRAM_TOPIC_ID=%s   <- %s' % (thread, nome))
        print()
    return 0


def main():
    nome = sys.argv[1] if len(sys.argv) > 1 else ''
    # "scopri" serve proprio a trovare il numero della conversazione: pretenderlo
    # in anticipo renderebbe il comando inutile.
    serve_solo_il_token = nome == 'scopri'
    if not TOKEN or (not CHAT and not serve_solo_il_token):
        print('Canale spento: mancano token o chat.', file=sys.stderr)
        return 3
    comandi = {
        'manda': comando_manda,
        'chiedi': comando_chiedi,
        'ascolta': comando_ascolta,
        'stato': comando_stato,
        'scopri': comando_scopri,
        'crea-sezione': comando_crea_sezione,
    }
    if nome not in comandi:
        print('Comando sconosciuto: %s' % nome, file=sys.stderr)
        return 1
    try:
        return comandi[nome]()
    except Exception as e:
        print('%s: %s' % (type(e).__name__, str(e)[:300]), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())

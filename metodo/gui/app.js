/* La schermata del runner — momento 1 (prima di lanciare).
   La pagina legge e basta: nessuna regola del Metodo vive qui. Lo stato arriva dal
   servitore (/api/stato), che lo chiede agli stessi strumenti del runner; i modelli da
   /api/modelli (solo quelli con una chiave); la benzina da /api/benzina. */
"use strict";

var scelte = { modalita: "fase", agente: "claude", modello: null,
               impegno: "high", ottimizza: false, tetto: 300, timeout: 30 };
var precompilata = false;   // le impostazioni di partenza si applicano una volta sola
var primaLettura = false;   // il momento su cui aprirsi si sceglie una volta sola
var appenaLanciata = false; // fra il lancio e il primo blocco passano pochi secondi

function $(id){ return document.getElementById(id); }
function el(tipo, classe, testo){
  var n = document.createElement(tipo);
  if (classe) n.className = classe;
  if (testo != null) n.textContent = testo;
  return n;
}
var migliaia = new Intl.NumberFormat("it-IT");
function soldi(n, valuta){
  var simboli = { USD: "$", EUR: "€", CNY: "¥" };
  return n.toLocaleString("it-IT", { minimumFractionDigits: 2, maximumFractionDigits: 2 }) +
         " " + (simboli[valuta] || valuta || "");
}

/* --- chiaro e scuro -------------------------------------------------------- */
function scuroOra(){
  var t = document.documentElement.getAttribute("data-theme");
  if (t) return t === "dark";
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}
function dipingiTema(){
  var salvato = null;
  try { salvato = localStorage.getItem("mv-tema"); } catch (e) {}
  if (salvato === "light" || salvato === "dark")
    document.documentElement.setAttribute("data-theme", salvato);
  $("tema").textContent = scuroOra() ? "Tema chiaro" : "Tema scuro";
}
$("tema").addEventListener("click", function(){
  var nuovo = scuroOra() ? "light" : "dark";
  document.documentElement.setAttribute("data-theme", nuovo);
  try { localStorage.setItem("mv-tema", nuovo); } catch (e) {}
  dipingiTema();
});

/* --- i due momenti ---------------------------------------------------------- */
function mostraMomento(quale){
  var prima = quale === "prima";
  $("t-prima").setAttribute("aria-selected", prima);
  $("t-durante").setAttribute("aria-selected", !prima);
  $("p-prima").hidden = !prima;
  $("p-durante").hidden = prima;
  // Il lavoro si guarda solo quando e' sotto gli occhi: chiedere ogni cinque secondi
  // com'e' messa una pagina nascosta e' lavoro per niente.
  guardaIlLavoro(!prima);
  if (!prima) caricaBenzina();
}
$("t-prima").addEventListener("click", function(){ mostraMomento("prima"); });
$("t-durante").addEventListener("click", function(){ mostraMomento("durante"); });

/* --- i gruppi a bottoni ----------------------------------------------------- */
function segna(id, valore){
  var bottoni = $(id).querySelectorAll("button");
  for (var i = 0; i < bottoni.length; i++)
    bottoni[i].setAttribute("aria-pressed",
      bottoni[i].getAttribute("data-valore") === String(valore) ? "true" : "false");
}
function alClic(id, azione){
  $(id).addEventListener("click", function(e){
    var b = e.target.closest("button");
    if (b) azione(b.getAttribute("data-valore"));
  });
}

/* --- avvisi ----------------------------------------------------------------- */
function avviso(testo){
  var a = $("avviso");
  if (!testo) { a.hidden = true; a.textContent = ""; return; }
  a.textContent = testo;
  a.hidden = false;
}

/* --- i numeri di una casella ------------------------------------------------ */
function mettiFact(id, grande, piccolo){
  var v = $(id);
  v.textContent = "";
  v.appendChild(document.createTextNode(grande));
  if (piccolo) v.appendChild(el("small", null, " " + piccolo));
}

/* --- lo stato del progetto ---------------------------------------------------- */
function caricaStato(){
  fetch("/api/stato?modalita=" + scelte.modalita + "&tetto=" + scelte.tetto)
    .then(function(r){ return r.json(); })
    .then(mostraStato)
    .catch(function(){ avviso("Il servitore della schermata non risponde: ricarica la pagina, " +
                              "e se continua chiudi e riapri la schermata."); });
}

function mostraStato(d){
  if (d.errore) avviso("Non riesco a leggere lo stato del progetto: " + d.errore);
  else avviso(null);

  if (d.progetto){
    $("nome-progetto").textContent = d.progetto.nome || "questo progetto";
    $("ramo").textContent = d.progetto.ramo || "";
  }

  // Si riparte da
  if (d.punto && d.punto.noto)
    mettiFact("riparte", "Fase " + d.punto.fase, "blocco " + d.punto.blocco);
  else
    mettiFact("riparte", "Dall'inizio", "prima corsa");

  // Roadmap e fase
  var faseDiRiferimento = d.punto && d.punto.noto ? String(d.punto.fase) : null;
  if (d.roadmap && d.roadmap.disponibile){
    var tot = d.roadmap.fatti + d.roadmap.da_fare;
    mettiFact("conta-roadmap", migliaia.format(d.roadmap.da_fare), "da fare su " + migliaia.format(tot));
    var trovata = null;
    for (var i = 0; i < d.roadmap.fasi.length; i++){
      var f = d.roadmap.fasi[i];
      if (faseDiRiferimento !== null && String(f.nome) === faseDiRiferimento) { trovata = f; break; }
      if (faseDiRiferimento === null && f.da_fare > 0) { trovata = f; break; }
    }
    if (trovata){
      $("nome-fase").textContent = "Fase " + trovata.nome;
      mettiFact("conta-fase", migliaia.format(trovata.da_fare),
                "da fare su " + migliaia.format(trovata.fatti + trovata.da_fare));
    } else {
      $("nome-fase").textContent = "Fase";
      mettiFact("conta-fase", "—", null);
    }
  } else {
    mettiFact("conta-roadmap", "—", null);
    $("nome-fase").textContent = "Fase";
    mettiFact("conta-fase", "—", null);
  }

  // Questa corsa: il numero che risponde alla domanda vera
  var p = d.previsione;
  if (!p && d.roadmap && !d.roadmap.disponibile)
    p = { blocchi: null, motivo: d.roadmap.motivo };
  if (!p){
    $("corsa-n").textContent = "Non so dirlo";
    $("corsa-perche").textContent = "";
  } else if (p.blocchi === null){
    $("corsa-n").textContent = "Non so dirlo";
    $("corsa-perche").textContent = p.motivo;
  } else if (p.blocchi === 0){
    $("corsa-n").textContent = "Nessun blocco";
    $("corsa-perche").textContent = p.motivo;
  } else {
    $("corsa-n").textContent = p.blocchi + (p.blocchi === 1 ? " blocco" : " blocchi");
    $("corsa-perche").textContent = p.motivo;
  }

  // Le impostazioni del progetto precompilano i controlli, una volta sola: dopo,
  // i controlli sono di chi li tocca e una rilettura non deve spostarli.
  if (!precompilata && d.impostazioni_di_partenza){
    var s = d.impostazioni_di_partenza;
    if (s.agente) scelte.agente = s.agente;
    if (s.modello) scelte.modello = s.modello;
    if (s.impegno) scelte.impegno = s.impegno;
    scelte.ottimizza = !!s.ottimizza;
    if (s.tetto) { scelte.tetto = s.tetto; $("in-tetto").value = s.tetto; }
    if (s.timeout) { scelte.timeout = s.timeout; $("in-timeout").value = s.timeout; }
    precompilata = true;
    dipingiControlli();
  }

  // Il bottone del lancio
  var bottone = $("lancia"), nota = $("nota-lancio");
  if (d.corsa && d.corsa.in_corso){
    bottone.disabled = true;
    // Una corsa avviata da runner.bat o dal terminale e' comunque una corsa su questo
    // progetto: dirlo e' il modo di non farne partire una seconda che si sovrascriva.
    nota.textContent = (d.corsa.da_questa_schermata
        ? "Una corsa è già in corso su questo progetto"
        : "Una corsa è già in corso su questo progetto, avviata fuori da questa schermata") +
      (d.corsa.avviata_il ? " (partita " + d.corsa.avviata_il + ")" : "") +
      ": chiudere questa finestra non la ferma.";
  } else if (p && p.blocchi === 0){
    bottone.disabled = true;
    nota.textContent = "Non risulta niente da fare" + (p.motivo ? ": " + p.motivo + "." : ".");
  } else {
    bottone.disabled = false;
    nota.textContent = "Il lavoro gira per conto suo: puoi chiudere questa finestra " +
                       "e riaprirla quando vuoi, la corsa non si ferma.";
  }

  // Alla prima lettura, e una volta sola: se una corsa sta girando la schermata si apre
  // sul lavoro. E' il motivo per cui esiste — chiudere la finestra a meta' corsa e
  // riaprirla deve far ritrovare il lavoro, non il modulo delle impostazioni.
  if (!primaLettura){
    primaLettura = true;
    if (d.corsa && d.corsa.in_corso) mostraMomento("durante");
  }
}

/* --- il lancio ---------------------------------------------------------------
   Qui si chiede e basta: cosa diventi la richiesta sulla riga di comando lo decide il
   servitore, e le regole del Metodo restano dove stanno (nel runner). */
function lancia(){
  var bottone = $("lancia"), nota = $("nota-lancio");
  bottone.disabled = true;
  nota.textContent = "Sto avviando la corsa…";
  fetch("/api/lancia", {
    method: "POST",
    // Il segno di riconoscimento della schermata: senza, il servitore non lancia niente.
    headers: { "Content-Type": "application/json", "X-Metodo-Villa": "si" },
    body: JSON.stringify(scelte)
  })
    .then(function(r){
      return r.json().then(function(d){ return { ok: r.ok, corpo: d }; });
    })
    .then(function(esito){
      if (!esito.ok){
        // Il perche' arriva dal servitore ed e' gia' scritto per essere letto: qui non si
        // riscrive, si mostra. Poi si rilegge lo stato, che sa se il bottone va riacceso.
        nota.textContent = "La corsa non è partita. " +
          (esito.corpo.errore || "Il servitore non ha detto perché.");
        bottone.disabled = false;
        return caricaStato();
      }
      appenaLanciata = true;
      mostraMomento("durante");
      caricaStato();
    })
    .catch(function(){
      nota.textContent = "Non sono riuscito a chiedere il lancio: il servitore della " +
                         "schermata non risponde. Ricarica la pagina e riprova.";
      bottone.disabled = false;
    });
}
$("lancia").addEventListener("click", lancia);

/* --- i controlli ------------------------------------------------------------- */
function dipingiControlli(){
  segna("seg-agente", scelte.agente);
  segna("seg-impegno", scelte.impegno);
  segna("seg-modalita", scelte.modalita);
  segna("seg-ottimizza", scelte.ottimizza ? "si" : "no");
  var eOpenCode = scelte.agente === "opencode";
  $("sel-modello").hidden = !eOpenCode;
  if (eOpenCode) caricaModelli();
  // Un modello puo' arrivare fissato dalle impostazioni del progetto anche con Claude:
  // dire "predefinito" sarebbe una bugia a schermo.
  else $("hint-modello").textContent = scelte.modello
    ? "Il modello e' fissato dalle impostazioni del progetto: " + scelte.modello + "."
    : "Claude Code lavora col suo modello predefinito.";
  dipingiOttimizza();
}

// Con un modello scelto a mano — da qui o dalle impostazioni del progetto — l'instradamento
// si spegne da solo (la regola e' del runner, e vale con qualunque programma): qui il
// controllo si disabilita e lo dice, invece di fingere di contare.
function dipingiOttimizza(){
  var manuale = !!scelte.modello;
  $("campo-ottimizza").className = manuale ? "field disabled" : "field";
  $("hint-ottimizza").textContent = manuale
    ? "Spento da solo: hai scelto un modello a mano, e tutti i blocchi vanno a quel modello."
    : "Acceso: cruciale → Opus 5 · importante → Kimi K3 · ordinario → GLM 5.3. " +
      "I blocchi senza peso restano al modello scelto qui sopra.";
}

alClic("seg-agente", function(v){ scelte.agente = v; if (v !== "opencode") scelte.modello = null; dipingiControlli(); });
alClic("seg-impegno", function(v){ scelte.impegno = v; segna("seg-impegno", v); });
alClic("seg-modalita", function(v){ scelte.modalita = v; segna("seg-modalita", v); caricaStato(); });
alClic("seg-ottimizza", function(v){ scelte.ottimizza = v === "si"; segna("seg-ottimizza", v); });

$("sel-modello").addEventListener("change", function(){
  scelte.modello = this.value || null;
  dipingiOttimizza();
});
$("in-tetto").addEventListener("change", function(){
  var n = parseInt(this.value, 10);
  if (isNaN(n)) n = 300;
  n = Math.min(1000, Math.max(1, n));
  this.value = n;
  scelte.tetto = n;
  caricaStato();
});
$("in-timeout").addEventListener("change", function(){
  var n = parseInt(this.value, 10);
  if (isNaN(n)) n = 30;
  n = Math.min(600, Math.max(1, n));
  this.value = n;
  scelte.timeout = n;
});

/* --- chi puo' lavorare (solo i modelli con una chiave) ----------------------- */
var modelliChiesti = false;
function caricaModelli(){
  if (modelliChiesti) return;
  modelliChiesti = true;
  $("hint-modello").textContent = "Sto chiedendo quali modelli hanno una chiave…";
  fetch("/api/modelli?fornitore=*")
    .then(function(r){ return r.json(); })
    .then(function(d){
      var sel = $("sel-modello");
      sel.textContent = "";
      sel.appendChild(el("option", null, "Il modello predefinito di OpenCode"))
         .value = "";
      if (!d.disponibile || !d.voci || !d.voci.length){
        $("hint-modello").textContent = (d.motivo || "Nessun modello con una chiave.") +
          " Le chiavi si registrano con: opencode providers login.";
        return;
      }
      // Un gruppo per fornitore: l'elenco intero non si leggerebbe.
      var gruppi = {};
      d.voci.forEach(function(v){
        var taglio = v.nome.indexOf("/");
        var fornitore = taglio > 0 ? v.nome.slice(0, taglio) : "";
        var corto = taglio > 0 ? v.nome.slice(taglio + 1) : v.nome;
        (gruppi[fornitore] = gruppi[fornitore] || []).push(corto);
      });
      Object.keys(gruppi).sort().forEach(function(fornitore){
        var g = el("optgroup");
        g.label = fornitore || "altri";
        gruppi[fornitore].forEach(function(corto){
          var o = el("option", null, corto);
          o.value = fornitore ? fornitore + "/" + corto : corto;
          g.appendChild(o);
        });
        sel.appendChild(g);
      });
      if (scelte.modello) sel.value = scelte.modello;
      scelte.modello = sel.value || null;
      dipingiOttimizza();
      $("hint-modello").textContent = "Compaiono solo i modelli per cui hai una chiave registrata.";
    })
    .catch(function(){
      modelliChiesti = false;
      $("hint-modello").textContent = "Non sono riuscito a chiedere i modelli: riprova selezionando di nuovo OpenCode.";
    });
}

/* --- la benzina ---------------------------------------------------------------- */
var NOMI_FORNITORI = {
  "zai-coding-plan": "GLM (Z.ai)",
  "moonshotai": "Kimi (Moonshot)",
  "moonshotai-cn": "Kimi (Moonshot CN)",
  "anthropic": "Claude (Anthropic)"
};
var MESI = ["gennaio","febbraio","marzo","aprile","maggio","giugno",
            "luglio","agosto","settembre","ottobre","novembre","dicembre"];

function nomeFornitore(f){ return NOMI_FORNITORI[f] || f; }

function quandoSiRicarica(epoch){
  if (!epoch) return null;
  var d = new Date(epoch * 1000), ora = new Date();
  var hh = ("0" + d.getHours()).slice(-2), mm = ("0" + d.getMinutes()).slice(-2);
  if (d.toDateString() === ora.toDateString()) return "alle " + hh + ":" + mm;
  return "il " + d.getDate() + " " + MESI[d.getMonth()];
}

function voceBenzina(nome, regime, numero, sotto, riempimento){
  var g = el("div", "gauge");
  var g1 = el("div", "g1");
  var n = el("span", "name", nome + " ");
  if (regime) n.appendChild(el("span", "regime " + (regime === "abbonamento" ? "sub-" : "pay"), regime));
  g1.appendChild(n);
  g1.appendChild(el("span", "num", numero));
  g.appendChild(g1);
  if (riempimento !== null && riempimento !== undefined){
    var t = el("div", "track");
    var f = el("div", "fill");
    f.style.width = Math.min(100, Math.max(0, riempimento)) + "%";
    t.appendChild(f);
    g.appendChild(t);
  }
  if (sotto) g.appendChild(el("div", "sub", sotto));
  return g;
}

// La stessa spia serve ai due momenti: prima di partire dice quanta ne hai, mentre
// lavora dice quanta ne resta. Una domanda sola ai fornitori, due riquadri dipinti.
function caricaBenzina(){
  fetch("/api/benzina")
    .then(function(r){ return r.json(); })
    .then(function(d){
      dipingiBenzina($("benzina"), d);
      dipingiBenzina($("benzina-durante"), d);
    })
    .catch(function(){
      [$("benzina"), $("benzina-durante")].forEach(function(box){
        box.textContent = "";
        box.appendChild(el("div", "attesa",
          "La spia della benzina non risponde: ricarica la pagina per riprovare."));
      });
    });
}

function dipingiBenzina(box, d){
  box.textContent = "";
  if (d.errore){
    box.appendChild(el("div", "attesa", "La spia della benzina non risponde: " + d.errore));
    return;
  }
  if (!d.fornitori || !d.fornitori.length){
    box.appendChild(el("div", "attesa",
      "Nessun fornitore con una chiave registrata: qui compariranno quota e saldo quando ce ne sarà una."));
    return;
  }
  d.fornitori.forEach(function(f){
    var nome = nomeFornitore(f.fornitore);
    if (f.stato === "ok" && f.finestre){
      f.finestre.forEach(function(fin){
        var etichetta = fin.etichetta ? nome + " · " + fin.etichetta : nome;
        var sotto = null;
        if (fin.rimasti != null && fin.totali != null){
          sotto = migliaia.format(fin.rimasti) + " crediti su " + migliaia.format(fin.totali);
          var ricarica = quandoSiRicarica(fin.reset_epoch);
          if (ricarica) sotto += " · si ricarica " + ricarica;
        } else if (fin.rimasti != null){
          sotto = migliaia.format(fin.rimasti) + " crediti rimasti";
        }
        box.appendChild(voceBenzina(etichetta, f.regime,
          fin.percentuale != null ? fin.percentuale + "%" : "—", sotto, fin.percentuale));
      });
    } else if (f.stato === "ok" && typeof f.saldo === "number"){
      box.appendChild(voceBenzina(nome, f.regime, soldi(f.saldo, f.valuta),
        "saldo disponibile presso il fornitore", null));
    } else if (f.stato === "errore"){
      // Un fornitore che non risponde non diventa uno zero: zero vorrebbe dire "finita".
      box.appendChild(voceBenzina(nome, null, "—", "Non risponde: " + f.motivo, null));
    } else {
      box.appendChild(voceBenzina(nome, null, "—", f.motivo || "Non disponibile.", null));
    }
  });
}

/* --- il momento 2: mentre lavora ------------------------------------------------
   Il servitore risponde con il record che il runner riscrive a ogni blocco e con la
   cronologia di questa corsa (/api/durante). Qui si dipinge e basta: cosa vuol dire
   una voce del diario lo dicono le regole del racconto (racconto.js). */
var OGNI_QUANTO = 5000;
var timerDurante = null;

function guardaIlLavoro(acceso){
  if (timerDurante){ clearInterval(timerDurante); timerDurante = null; }
  if (!acceso) return;
  caricaDurante();
  timerDurante = setInterval(caricaDurante, OGNI_QUANTO);
}

function caricaDurante(){
  return fetch("/api/durante")
    .then(function(r){ return r.json(); })
    .then(mostraDurante)
    .catch(function(){
      niente($("adesso"), "Il servitore della schermata non risponde: ricarica la pagina, " +
                          "e se continua chiudi e riapri la schermata.");
    });
}

function niente(box, testo){
  box.textContent = "";
  box.appendChild(el("div", "empty", testo));
}

function mostraDurante(d){
  seLaCorsaEFinita(d);
  dipingiFerma(d);
  if (!d || !d.disponibile){
    niente($("adesso"), attesaDelPrimoBlocco() || (d && d.motivo) ||
      "Non c'è ancora niente da guardare: il lavoro si racconta qui appena parte una corsa.");
    dipingiConsumo(null);
    dipingiCronologia([]);
    return;
  }
  if (d.in_corso){
    appenaLanciata = false;
    dipingiInCorso($("adesso"), d.in_corso);
  } else {
    niente($("adesso"), attesaDelPrimoBlocco() ||
      "In questo momento non sta girando nessun blocco." +
      (d.corsa && d.corsa.iniziata_il ? " La corsa è partita il " + d.corsa.iniziata_il + "." : ""));
  }
  dipingiConsumo(d.in_corso);
  dipingiCronologia(d.cronologia || []);
}

// Fra il lancio e il primo blocco passano pochi secondi, in cui il record della corsa non
// c'e' ancora o e' quello di prima: dire "niente da guardare" a chi ha appena premuto il
// bottone sembrerebbe un lancio fallito.
function attesaDelPrimoBlocco(){
  return appenaLanciata
    ? "La corsa è partita: il primo blocco compare qui fra pochi secondi."
    : null;
}

// La corsa finisce mentre si guarda: il bottone del lancio va riacceso, e nessuno lo fa
// se non si rilegge lo stato. Il confronto e' col giro precedente, per chiederlo una
// volta sola invece che ogni cinque secondi.
var corsaVivaPrima = null;
function seLaCorsaEFinita(d){
  var viva = !!(d && d.corsa_viva);
  if (corsaVivaPrima === true && !viva){ appenaLanciata = false; caricaStato(); }
  corsaVivaPrima = viva;
}

/* --- fermarsi dopo il blocco in corso -----------------------------------------
   Non si uccide niente: si chiede, e il runner raccoglie la richiesta quando il blocco
   in corso e' finito per davvero — con la sua verifica e il suo commit. */
function dipingiFerma(d){
  var bottone = $("ferma"), nota = $("nota-ferma");
  var viva = !!(d && d.corsa_viva);
  bottone.hidden = !viva;
  nota.hidden = !viva;
  if (!viva) return;
  if (d.ferma_chiesta){
    bottone.disabled = true;
    nota.textContent = "Chiesto: il blocco in corso arriva alla fine, poi la corsa si " +
                       "ferma. Riparte da dove è arrivata quando vuoi.";
  } else {
    bottone.disabled = false;
    nota.textContent = "Il blocco in corso non si interrompe a metà: si ferma quando ha " +
                       "finito, verificato e salvato.";
  }
}

$("ferma").addEventListener("click", function(){
  var bottone = $("ferma");
  bottone.disabled = true;
  $("nota-ferma").textContent = "Sto lasciando la richiesta…";
  fetch("/api/ferma", { method: "POST", headers: { "X-Metodo-Villa": "si" } })
    .then(function(r){
      return r.json().then(function(d){ return { ok: r.ok, corpo: d }; });
    })
    .then(function(esito){
      if (!esito.ok){
        $("nota-ferma").textContent = esito.corpo.errore ||
          "Il servitore non ha detto perché non è riuscito a fermarla.";
        bottone.disabled = false;
        return;
      }
      caricaDurante();
    })
    .catch(function(){
      $("nota-ferma").textContent = "Non sono riuscito a chiedere di fermarsi: il " +
                                    "servitore della schermata non risponde.";
      bottone.disabled = false;
    });
});

function pastiglia(classe, testo){ return el("span", "chip" + (classe ? " " + classe : ""), testo); }

function dipingiInCorso(box, b){
  box.textContent = "";
  var riga = el("div", "now");
  var battito = el("span", "pulse");
  battito.setAttribute("aria-hidden", "true");
  riga.appendChild(battito);

  var testa = el("div", "testa");
  testa.appendChild(el("div", "id", "Blocco " + (b.blocco || "—")));
  testa.appendChild(el("div", "ttl", b.titolo || "senza titolo in roadmap"));
  var chips = el("div", "chips");
  if (b.motore) chips.appendChild(pastiglia("eng", b.motore));
  if (b.modello) chips.appendChild(pastiglia(null, b.modello));
  if (b.peso) chips.appendChild(pastiglia(null, racconto.pesoConSegno(b.peso)));
  if (b.impegno) chips.appendChild(pastiglia(null, "impegno " + racconto.impegnoInItaliano(b.impegno)));
  if (b.promosso) chips.appendChild(pastiglia("up", "promosso dopo l'errore"));
  var da = racconto.daQuando(b.iniziato_il);
  if (da) chips.appendChild(pastiglia(null, da));
  testa.appendChild(chips);
  riga.appendChild(testa);
  box.appendChild(riga);

  // Oltre la previsione non si dice "13º di 12": o la corsa si ferma qui, o la
  // previsione era sbagliata. In tutti e due i casi meglio tacere (regola del runner).
  if (b.posizione && b.previsti && b.posizione <= b.previsti){
    var restano = b.previsti - b.posizione;
    var prog = el("div", "prog");
    var txt = el("div", "txt");
    txt.appendChild(el("span", null, b.posizione + "º blocco di " + b.previsti + " previsti"));
    txt.appendChild(el("span", null, restano > 0
      ? "dopo questo ne restano " + restano : "è l'ultimo previsto"));
    prog.appendChild(txt);
    var t = el("div", "track"), f = el("div", "fill");
    f.style.width = Math.round(b.posizione / b.previsti * 100) + "%";
    t.appendChild(f);
    prog.appendChild(t);
    box.appendChild(prog);
  }
}

function dipingiConsumo(b){
  var box = $("consumo-corsa");
  box.textContent = "";
  if (!b){
    box.appendChild(el("div", "attesa", "Quanto sta consumando si vede mentre un blocco gira."));
    return;
  }
  box.appendChild(voceBenzina("Questa corsa", null, migliaia.format(b.speso_token || 0),
                              "unità consumate da quando è partita", null));
  // La spesa in denaro compare solo se c'e' davvero: uno zero accanto a un modello in
  // abbonamento non e' un'informazione, e' un dubbio.
  if (b.speso_costo > 0)
    box.appendChild(voceBenzina("Spesa", null, soldi(b.speso_costo, "USD"),
                                "presso i fornitori a consumo", null));
}

function dipingiCronologia(voci){
  $("titolo-cronologia").textContent =
    voci.length ? "Blocchi finiti — " + voci.length : "Blocchi finiti";
  var box = $("cronologia");
  // Un riquadro aperto resta aperto: la pagina si ridisegna da sola ogni pochi secondi,
  // e richiuderlo sotto le mani di chi sta leggendo sarebbe insopportabile.
  var aperti = {};
  Array.prototype.forEach.call(box.querySelectorAll("details.blk[open]"), function(d){
    aperti[d.getAttribute("data-chiave")] = true;
  });
  box.textContent = "";
  if (!voci.length){
    box.appendChild(el("div", "empty", "Ancora nessun blocco chiuso in questa corsa: appena " +
      "uno finisce compare qui, il più recente in cima."));
    return;
  }
  voci.forEach(function(v){ box.appendChild(riquadro(v, aperti)); });
}

function riquadro(v, aperti){
  var stato = racconto.statoDelBlocco(v);
  var chiave = (v.quando || "") + "|" + (v.blocco || "");
  var d = el("details", "blk");
  d.setAttribute("data-chiave", chiave);
  if (aperti[chiave]) d.open = true;

  var s = el("summary");
  var segno = el("span", "badge " + stato.classe, stato.segno);
  // Il segno da solo non dice come e' andata: la parola resta a portata di puntatore
  // e di lettore di schermo.
  segno.title = stato.parola;
  s.appendChild(segno);

  var head = el("span", "head");
  var l1 = el("span", "line1");
  l1.appendChild(el("span", "bid", v.blocco || ""));
  l1.appendChild(el("span", "say", racconto.rigaCorta(v)));
  head.appendChild(l1);
  var sotto = racconto.sottoriga(v);
  if (sotto) head.appendChild(el("span", "line2", sotto));
  s.appendChild(head);

  var freccia = el("span", "caret", "▸");
  freccia.setAttribute("aria-hidden", "true");
  s.appendChild(freccia);
  d.appendChild(s);
  d.appendChild(dentroIlRiquadro(v, stato));
  return d;
}

function dentroIlRiquadro(v, stato){
  var c = el("div", "body");
  // Per esteso si legge il racconto in italiano di tutti i giorni. Il riassunto tecnico
  // serve all'agente del blocco dopo, non a chi guarda: entra solo quando il racconto
  // non c'e' (i blocchi falliti non lo scrivono) ed e' l'unica cosa rimasta da dire.
  var disteso = (v.per_villa || v.summary || "").trim();
  if (disteso) c.appendChild(el("p", null, disteso));

  var kv = el("dl", "kv");
  function voce(k, valore){
    if (!valore) return;
    kv.appendChild(el("dt", null, k));
    kv.appendChild(el("dd", null, valore));
  }
  voce("Esito", stato.parola);
  voce("Motore", v.motore);
  voce("Consumo", v.consumo);
  voce("Verifica", v.verifica);
  voce("Chiuso", v.quando);
  if (v.file && v.file.length){
    kv.appendChild(el("dt", null, "File"));
    var dd = el("dd");
    v.file.forEach(function(f){ dd.appendChild(el("code", null, f)); });
    kv.appendChild(dd);
  }
  c.appendChild(kv);
  return c;
}

/* --- avvio ---------------------------------------------------------------------- */
dipingiTema();
// Su quale momento aprirsi lo decide lo stato del progetto, non appena arriva: se una
// corsa sta girando (anche avviata da runner.bat) la schermata si apre sul lavoro.
caricaStato();
caricaBenzina();

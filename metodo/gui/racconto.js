/* Le regole del racconto: come una voce del diario diventa una riga leggibile.
   Qui dentro non si tocca la pagina e non si chiede niente al servitore — sono
   funzioni pure, e per questo si possono provare da sole (tests/test_racconto.js).
   La pagina dipinge; queste righe decidono soltanto COSA c'e' scritto. */
"use strict";
(function (radice) {

  /* I cinque stati di un blocco chiuso (mappa dell'esperienza, "Il riquadro di un
     blocco chiuso"), piu' il caso di una voce che non dice come e' andata. */
  var STATI = {
    fatto:    { chiave: "fatto",    classe: "ok",   segno: "✓", parola: "fatto" },
    fallito:  { chiave: "fallito",  classe: "bad",  segno: "✕", parola: "fallito" },
    promosso: { chiave: "promosso", classe: "up",   segno: "↑", parola: "rifatto con un motore più forte" },
    fermato:  { chiave: "fermato",  classe: "hold", segno: "⏸", parola: "fermato: serve Villa" },
    saltato:  { chiave: "saltato",  classe: "hold", segno: "»", parola: "saltato: tocca a Villa" },
    ignoto:   { chiave: "ignoto",   classe: "hold", segno: "·", parola: "esito non registrato" }
  };

  var IMPEGNO = { low: "basso", medium: "medio", high: "alto", max: "massimo" };
  var SEGNO_PESO = { cruciale: "🔴", importante: "🟡", ordinario: "🟢" };

  function testo(x) { return String(x == null ? "" : x).replace(/\s+/g, " ").trim(); }

  /* Com'e' andata. Lo dice lo Status scritto dal runner; il resto della voce serve
     a distinguere i due modi di fermarsi. */
  function statoDelBlocco(voce) {
    voce = voce || {};
    var stato = testo(voce.status).toUpperCase();
    var haLavorato = !!testo(voce.motore);
    if (stato === "CONTINUE" || stato === "PHASE_COMPLETE") {
      // "Promosso" e' scritto accanto al motore: quel blocco era gia' fallito una volta
      // ed e' stato rifatto un gradino piu' su (cap. 22). Vale solo se poi e' andata
      // bene: un blocco promosso e fallito di nuovo resta un blocco fallito.
      return /promosso/i.test(voce.motore || "") ? STATI.promosso : STATI.fatto;
    }
    if (stato === "ERROR" || stato === "FAILED") return STATI.fallito;
    if (stato === "CHECKPOINT" || stato === "BLOCKED") {
      // Senza motore nessuna sessione e' stata aperta: il runner non ha nemmeno
      // cominciato, perche' quel blocco e' di quelli che chiedono Villa. Col motore
      // invece il lavoro c'e' stato, e ci si e' fermati per chiedere.
      return haLavorato ? STATI.fermato : STATI.saltato;
    }
    return STATI.ignoto;
  }

  /* La riga che si vede a riquadro chiuso: in italiano di tutti i giorni, quindi il
     racconto per Villa e non il riassunto tecnico (che serve all'agente del blocco
     dopo). Quando quel racconto non c'e' — i blocchi falliti non lo scrivono — meglio
     il riassunto che una riga vuota. */
  function rigaCorta(voce) {
    voce = voce || {};
    return primaFrase(voce.per_villa) || primaFrase(voce.summary) ||
           "Nessun racconto scritto per questo blocco.";
  }

  function primaFrase(t) {
    var s = testo(t);
    if (!s) return "";
    var taglio = s.search(/[.!?](\s|$)/);
    return taglio > 0 ? s.slice(0, taglio + 1) : s;
  }

  /* La riga piccola sotto: quanto e' durato e quanto e' costato, cosi' come il runner
     le ha gia' scritte. Quello che manca semplicemente non compare. */
  function sottoriga(voce) {
    voce = voce || {};
    return [testo(voce.durata), testo(voce.consumo)].filter(Boolean).join(" · ");
  }

  /* Da quanto sta girando il blocco in corso. Le date del runner sono ore locali
     ("2026-08-16 10:20:00"): si leggono a pezzi, perche' i browser non sono d'accordo
     su come intendere quella forma. */
  function leggiData(s) {
    var p = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/.exec(testo(s));
    if (!p) return null;
    return new Date(+p[1], +p[2] - 1, +p[3], +p[4], +p[5], +p[6]);
  }

  function daQuando(inizio, adesso) {
    var d = leggiData(inizio);
    if (!d) return null;
    var minuti = Math.floor(((adesso || new Date()) - d) / 60000);
    if (minuti < 0) return null;          // orologio indietro: meglio tacere
    if (minuti < 1) return "da poco";
    if (minuti < 60) return "da " + minuti + " min";
    return "da " + Math.floor(minuti / 60) + " h " + (minuti % 60) + " min";
  }

  function impegnoInItaliano(x) { return IMPEGNO[testo(x)] || testo(x); }

  function pesoConSegno(p) {
    var s = testo(p);
    return s ? s + (SEGNO_PESO[s] ? " " + SEGNO_PESO[s] : "") : "";
  }

  var racconto = {
    STATI: STATI,
    statoDelBlocco: statoDelBlocco,
    rigaCorta: rigaCorta,
    sottoriga: sottoriga,
    daQuando: daQuando,
    leggiData: leggiData,
    impegnoInItaliano: impegnoInItaliano,
    pesoConSegno: pesoConSegno
  };

  if (typeof module === "object" && module.exports) module.exports = racconto;
  else radice.racconto = racconto;

})(typeof globalThis !== "undefined" ? globalThis : this);

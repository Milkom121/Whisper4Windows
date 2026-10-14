/* LE REGOLE DEL PROTOTIPO — l'unico file che vale la pena scrivere bene.
 *
 * Non sa niente della pagina: niente `document`, niente bottoni, niente colori.
 * E' questa separazione che permette, quando la risposta arriva, di sollevare
 * questo file e portarlo nel codice vero buttando la pagina intorno.
 *
 * Ogni regola prende lo stato e ne restituisce uno nuovo, insieme a cosa dire:
 *   { stato: <il nuovo stato>, permesso: true|false, dice: "in parole" }
 *
 * `permesso` colora la riga nel diario: verde quando la cosa si e' potuta fare,
 * arancione quando la regola l'ha impedita. Il momento utile di un prototipo e'
 * proprio quello — quando Villa dice «aspetta, questo non dovrebbe essere
 * possibile».
 */
const Regole = {

  statoIniziale() {
    return {
      // Lo stato si scrive nella lingua del mestiere, perche' Villa lo legge
      // a schermo mentre clicca.
      esempio: "sostituisci questo oggetto con lo stato vero della regola",
    };
  },

  /* Esempio di gesto permesso.
  chiudi(stato) {
    if (!stato.tutteLeProveReggono) {
      return { stato, permesso: false, dice: "non si puo': una prova non regge" };
    }
    return { stato: { ...stato, chiusa: true }, permesso: true, dice: "chiusa" };
  },
  */
};

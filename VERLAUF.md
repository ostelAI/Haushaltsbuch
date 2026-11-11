# Verlauf: Wünsche und Entscheidungen

Was Christian (per Chat oder Sprachnachricht) gewünscht hat und was daraus umgesetzt wurde.
Neueste Einträge oben. Jede Änderung an der App bekommt hier einen Eintrag, damit man in
Claude Code nachvollziehen kann, **warum** etwas so ist — nicht nur was sich geändert hat.

Format je Eintrag: Datum · Version · Wunsch (in Christians Worten, sinngemäß) · Umsetzung · Offen.

---

## 2026-11-11 · v1.6.00 · Erklärungen, ehrliches Tagesbudget, abgesetzte Filter

**Wunsch:** Christian fiel auf, dass „Pro Tag noch 51,36 €“ und die Prognose „ca. 34 €/Tag“
sich zu widersprechen schienen. Nachfrage ergab: kein Rechenfehler, aber die obere Zahl
kannte das Monatsbudget nicht. Dazu: „Es muss richtig als Erklärung dastehen oder mach ein
kleines Fragezeichen hin, das aufploppt.“ Und: Die neuen Suchfelder „überliest man“, sie
müssten „eingekesselt“ sein — Eingabe, Suchfeld und Liste als getrennte Blöcke.

**Umgesetzt:**
- **Pro Tag noch** rechnet bei gesetztem Monatsbudget gegen dieses Budget
  (`min(rest, budget − variable) / Resttage`) statt gegen alles Verfügbare. Bei Christians
  Zahlen: 30,85 € statt 51,36 €. Darunter steht dann „· vom Budget“, damit die Grundlage
  sichtbar ist. Ohne Budget bleibt es wie vorher.
- **Fragezeichen** (antippbar, eigenes Fenster — `title` hilft auf dem Handy nicht) bei
  Noch verfügbar, Pro Tag noch, der Status-Ampel, Monatliches Budget, Prognose und
  Hausausbau. Texte in der Konstante `HILFE`. Der Prognose-Text betont, dass sie eine
  **Messung** ist und keine Erlaubnis — genau das war Christian nicht mehr präsent.
- **Filterkasten:** Such- und Sortierfelder sitzen in `.filterbox` mit eigenem Hintergrund,
  Rahmen und der Überschrift „Suchen und sortieren“. Gilt auch für „Ausgaben im Monat“.
- **Fixkosten und Einnahmen** sind in zwei Karten geteilt: „Neue feste Ausgabe“ /
  „Alle festen Ausgaben“ (analog bei Einnahmen), mit Posten-Zähler im Kopf.

**Offen:** Keine Datenbankänderung nötig.

## 2026-11-11 · v1.5.03 · Filter in Fixkosten und Einnahmen

**Wunsch:** „Kannst du bitte in den Fixkosten einen Filter mit einbauen, wo man nach
Versicherung suchen kann oder nach Alphabet oder nach… Genauso bei den Einnahmen.“
Gemeint war die Filterzeile, die es bei „Ausgaben im Monat“ schon gibt.

**Umgesetzt:**
- Filterzeile über beiden Listen, gleiche Machart wie bei den täglichen Ausgaben.
- Fixkosten: Suchfeld (trifft Bezeichnung **und** Kategoriename — „Versicherung“ findet
  deshalb auch die Kfz-Versicherung unter Mobilität), Kategoriefilter, Sortierung nach
  Kategorie+Tag (wie bisher), Name A–Z, Betrag absteigend oder Fälligkeitstag.
- Einnahmen: Suchfeld (Name und Person), Personenfilter (nur sichtbar, wenn Namen
  hinterlegt sind), Sortierung nach Tag, Name oder Betrag.
- Bei aktivem Filter steht darunter „3 von 6 Posten · 192,59 € im Monat“ — die Summe
  bezieht sich auf die Treffer, nicht auf alles.
- Die Sortierwahl liegt im Browser (`haushaltsbuch.fixSort` / `.incSort`) und übersteht
  einen Neustart; der Filtertext bewusst nicht, der soll bei jedem Besuch leer sein.

**Offen:** Keine Datenbankänderung nötig.

## 2026-10-26 · v1.5.02 · Jede Ansicht zieht vom Rahmen ab

**Wunsch:** „Es zieht nicht ab beim neuen Reiter, bei Kalkuliert — prüfe auch bei Aufgewendet.“
Bisher zeigte der Kopf in beiden Ansichten nur Rahmen − Aufgewendet; Kalkuliertes ging
bewusst nicht ab. Christian will, dass auch Kalkuliertes abgezogen wird.

**Umgesetzt:**
- Der große Betrag oben hängt von der Ansicht ab:
  Kalkuliert → „noch übrig laut Kalkulation“ = Rahmen − kalkuliert (Balken orange),
  Aufgewendet → „noch übrig“ = Rahmen − aufgewendet (Balken grün).
- Die Zeile Rahmen / Kalkuliert / Aufgewendet bleibt in beiden Ansichten sichtbar.
- Beide getestet: neuer Eintrag senkt den Betrag sofort in seiner Ansicht.

## 2026-10-26 · v1.5.01 · Hausausbau: Kalkuliert / Aufgewendet

**Wunsch:** „Ist“ ist kein schönes Wort. Die zwei Ansichten sollen „Kalkuliert“ und
„Aufgewendet“ heißen, und man soll sie gut unterscheiden können.

**Umgesetzt:**
- Umschalter und alle Texte umbenannt (Neue Kalkulation, Kalkuliert nach Gewerk,
  Aufgewendet nach Gewerk, „über Kalkulation“, „Noch nicht kalkuliert“).
- Farblich getrennt: Kalkuliert = Orange (`--c2`), Aufgewendet = Grün (`--accent`) —
  aktiver Umschalter, Streifen oben an den Karten, Button „Kalkulieren“.
- Intern heißen die Ansichten weiter `geplant` / `bezahlt` (`data-abansicht`,
  localStorage `haushaltsbuch.ausbauAnsicht`), die Tabelle weiter `ausbau_plan`.

**Erledigt von Christian:** SQL-Nachtrag „Hausausbau geplant“ in Supabase ausgeführt.

## 2026-10-26 · v1.5.00 · Hausausbau: zwei Unterkategorien

**Wunsch:** Im Reiter Hausausbau zwei Unterkategorien: eine, in die man einträgt, was man
einplant, und eine für das, was tatsächlich ausgegeben wurde (wie bisher).
Vorschau als Design-Mockup gezeigt und von Christian freigegeben.

**Umgesetzt:**
- Umschalter oben im Reiter; die App merkt sich die letzte Auswahl.
- Geplante Posten je Gewerk (Betrag, Gewerk, Wofür) — anlegen, bearbeiten, löschen.
  Gehen **nicht** vom Rahmen ab.
- „Nach Gewerk“ zeigt Ausgegebenes gegen Geplantes, über Plan wird markiert.
- Kopf: Rahmen, Geplant, Ausgegeben nebeneinander, Balken mit beiden Werten,
  „noch nicht verplant“ = Rahmen − Geplant, „noch übrig“ = Rahmen − Ausgegeben.
- Neue Tabelle `ausbau_plan` (eigene Tabelle statt Spalte, damit ältere App-Fassungen
  Geplantes nie als bezahlt mitzählen) — Nachtrag am Ende von `schema.sql`.

## 2026-10-14 · v1.4.00 · Neuer Reiter Hausausbau

Eigene Buchführung für den Hausausbau mit Rahmen, Gewerken und Ausgaben, getrennt vom
Haushaltsbudget. (Vor Einführung dieses Verlaufs; Details siehe Änderungsverlauf in
`index.html`, Konstante `AENDERUNGEN`.)

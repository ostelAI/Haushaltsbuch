# Verlauf: Wünsche und Entscheidungen

Was Christian (per Chat oder Sprachnachricht) gewünscht hat und was daraus umgesetzt wurde.
Neueste Einträge oben. Jede Änderung an der App bekommt hier einen Eintrag, damit man in
Claude Code nachvollziehen kann, **warum** etwas so ist — nicht nur was sich geändert hat.

Format je Eintrag: Datum · Version · Wunsch (in Christians Worten, sinngemäß) · Umsetzung · Offen.

---

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

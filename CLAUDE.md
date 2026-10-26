# Hinweise für Claude

- Christian ist Product Owner, kein Entwickler: Er sagt, was er will, Claude schreibt den Code.
  Antworten auf Deutsch, direkt und praktisch.
- **Vor jeder Arbeit `VERLAUF.md` lesen.** Dort steht, was Christian gewünscht hat und warum
  Dinge so gebaut sind.
- **Nach jeder Änderung `VERLAUF.md` ergänzen** (neuester Eintrag oben): Wunsch, Umsetzung,
  Offenes. Das gilt auch für Änderungen, die aus dem Claude-Chat am Handy kommen.
- Bei neuer Version: `APP_VERSION` hochsetzen und einen Eintrag in `AENDERUNGEN`
  (`index.html`) ergänzen — das ist der Text, den die Nutzer in der App unter „Neues“ sehen.
- Datenbankänderungen als Nachtrag ans Ende von `schema.sql` (idempotent:
  `if not exists`, `drop policy if exists`) und Christian sagen, dass er sie in Supabase
  ausführen muss.

# Haushaltsbuch

Gemeinsames Haushaltsbuch für zwei Personen mit getrennten Logins: Einnahmen,
feste Kosten, tägliche Ausgaben und der Blick darauf, was diesen Monat noch
übrig ist.

Die App ist eine einzelne HTML-Datei ohne Build-Schritt. Die Daten liegen in
einer eigenen Supabase-Datenbank, damit beide dieselben Zahlen sehen — live, auf
jedem Gerät.

---

## Einrichtung — vier Schritte

### 1. Supabase-Projekt anlegen

1. Auf [supabase.com](https://supabase.com) ein kostenloses Konto anlegen.
2. **New project** → Name z. B. `haushaltsbuch`, Region **Frankfurt (eu-central-1)**,
   Datenbank-Passwort vergeben (kannst du danach vergessen, die App braucht es nicht).
3. Warten, bis das Projekt bereit ist (ein bis zwei Minuten).

### 2. Tabellen anlegen

1. Im Projekt links auf **SQL Editor** → **New query**.
2. Den kompletten Inhalt von [`schema.sql`](schema.sql) hineinkopieren.
3. **Run** drücken. Es sollte ohne Fehler durchlaufen.

Das legt die Tabellen an und schaltet die Zugriffsregeln scharf: Ohne Anmeldung
und ohne Mitgliedschaft in einem Haushalt sind alle Tabellen leer.

### 3. Zugangsdaten eintragen

1. Links auf **Project Settings** → **API**.
2. **Project URL** und den Schlüssel **anon public** kopieren.
3. Beides in [`config.js`](config.js) eintragen:

```js
window.HB_CONFIG = {
  url:     "https://xxxxxxxxxxxx.supabase.co",
  anonKey: "eyJhbGci..."
};
```

> **Wichtig:** Nimm den `anon public` key, niemals den `service_role` key. Der
> `service_role` key umgeht alle Zugriffsregeln und darf nirgends im Browser
> oder in einem Repository landen.
>
> Dass der `anon` key öffentlich sichtbar ist, ist beabsichtigt und
> ungefährlich — geschützt werden die Daten durch die Regeln aus `schema.sql`,
> nicht durch Geheimhaltung dieses Schlüssels.

### 4. E-Mail-Bestätigung ausschalten

Die App meldet mit **E-Mail und Passwort** an — bewusst ohne Bestätigungslink.
Der eingebaute Mailversand von Supabase erlaubt auf dem kostenlosen Tarif nur
wenige Nachrichten pro Stunde, und genau daran scheitert sonst jeder zweite
Anmeldeversuch.

**Authentication** → **Sign In / Providers** → **Email**:

- **Confirm email** → **aus**
- **Allow new users to sign up** → **an**

Ohne diese Einstellung legt Supabase zwar Konten an, lässt aber niemanden
hinein, bis eine Bestätigungsmail angeklickt wurde.

> Ist das unsicher? Für eine App, die nur zwei Leute kennen, nein. Die
> Bestätigung beweist lediglich, dass jemandem die E-Mail-Adresse gehört. Wer
> ohne Einladungscode ein Konto anlegt, sieht ohnehin nichts — er landet auf
> einem leeren Bildschirm ohne Zugriff auf euren Haushalt.

Fertig. Beim ersten Öffnen legst du dir ein Konto an, danach einen Haushalt,
und über **Einstellungen → Zweite Person einladen** einen Code für die zweite
Person.

---

## Lokal ausprobieren

Im Projektordner:

```bash
python -m http.server 8777
```

Dann `http://localhost:8777/` im Browser öffnen.

---

## Ins Netz stellen

### GitHub Pages

Voraussetzung ist ein **öffentliches** Repository — GitHub Pages funktioniert
mit kostenlosen Konten nur so. Das ist unproblematisch, solange in `config.js`
ausschließlich der `anon` key steht (siehe Schritt 3).

```bash
git add -A
git commit -m "Haushaltsbuch"
git remote add origin https://github.com/DEINNAME/Haushaltsbuch.git
git push -u origin main
```

Danach im Repository auf **Settings → Pages** → Source: **Deploy from a branch**,
Branch `main`, Ordner `/ (root)`. Nach ein paar Minuten läuft die Seite unter
`https://DEINNAME.github.io/Haushaltsbuch/`.

Diese Adresse dann in Supabase unter **Site URL** und **Redirect URLs**
eintragen (Schritt 4).

### Netlify — falls du kein öffentliches Repository willst

Auf [app.netlify.com/drop](https://app.netlify.com/drop) den Projektordner ins
Browserfenster ziehen. Fertig, ohne Repository. Nachteil: Änderungen musst du
jedes Mal neu hochladen.

---

## Zu zweit nutzen

1. Du legst dir ein Konto an und danach den Haushalt.
2. **Einstellungen → Zweite Person einladen** → Code erscheint (14 Tage gültig).
3. Den Code weitergeben — Zettel, Signal, wie ihr wollt.
4. Die zweite Person öffnet dieselbe Adresse, legt sich mit **ihrer eigenen**
   E-Mail und einem eigenen Passwort ein Konto an und trägt den Code unter
   „Einer Einladung folgen" ein.

Ab dann seht ihr dieselben Zahlen, jeder mit eigenem Login.

---

## Kassenzettel fotografieren (optional)

Die App kann einen Kassenzettel abfotografieren und Betrag, Datum, Geschäft und
Kategorie ins Formular schreiben. **Eingetragen wird nichts automatisch** — das
Ergebnis füllt nur die Felder, du prüfst und drückst „Eintragen". Ein still
falsch übernommener Betrag wäre schlimmer als gar keine Automatik.

Ohne die folgenden drei Schritte ist der Knopf zwar da, meldet aber einen
Fehler. Alles andere in der App funktioniert unabhängig davon.

### 1. API-Schlüssel besorgen

Auf [console.claude.com](https://console.claude.com) ein Konto anlegen, Guthaben
aufladen (5 $ reichen für Jahre) und unter **API Keys** einen Schlüssel
erstellen. Er beginnt mit `sk-ant-`.

**Dieser Schlüssel darf niemals in `config.js` oder sonst in dieses
Repository.** Anders als der Supabase-anon-key ist er nicht für die
Öffentlichkeit gemacht — wer ihn hat, lässt auf deine Rechnung lesen. Er gehört
ausschließlich als Secret zu Supabase, Schritt 2.

### 2. Funktion veröffentlichen

Einmalig die [Supabase CLI](https://supabase.com/docs/guides/cli) installieren,
dann im Projektordner:

```bash
supabase login
supabase link --project-ref DEINE-PROJEKT-ID
supabase secrets set ANTHROPIC_API_KEY=sk-ant-DEIN-SCHLUESSEL
supabase functions deploy beleg-lesen
```

Die Projekt-ID ist der Teil vor `.supabase.co` in deiner Projekt-URL.

### 3. Fertig

Der Knopf **Kassenzettel fotografieren** steht unter *Ausgaben eintragen*. Auf
dem Handy öffnet er direkt die Kamera.

### Was das kostet

Rund **0,3 Cent pro Beleg** — bei 30 Belegen im Monat etwa 10 Cent. Das ist der
einzige laufende Kostenpunkt der App; Supabase und GitHub Pages bleiben im
kostenlosen Rahmen. Die Edge Function prüft die Anmeldung, es kann also niemand
Fremdes auf deine Rechnung lesen lassen.

### Was mit dem Foto passiert

Das Bild wird im Browser verkleinert, einmal zum Auslesen geschickt und danach
verworfen. Es wird **nirgends gespeichert** — weder bei Supabase noch sonstwo.
Verarbeitet wird es bei Anthropic; wenn dir das bei Belegen unangenehm ist,
lass diese Funktion einfach weg und trag wie bisher von Hand ein.

Welches Modell liest, steht als einzelne Zeile oben in
`supabase/functions/beleg-lesen/index.ts`. Voreingestellt ist das schnelle und
günstige Haiku 4.5. Wenn zerknitterte Bons schlecht erkannt werden, lohnt ein
Wechsel auf `claude-opus-5-5` — dann kostet ein Beleg etwa 1,5 Cent.

---

## Was in welcher Datei steckt

| Datei | Zweck |
|---|---|
| `index.html` | Die komplette App — Oberfläche, Berechnung, Datenbankzugriff |
| `config.js` | Deine zwei Supabase-Zugangsdaten |
| `schema.sql` | Tabellen und Zugriffsregeln, einmalig in Supabase ausführen |
| `supabase/functions/beleg-lesen/` | Liest fotografierte Kassenzettel aus. Optional, siehe oben |
| `haushaltsbuch.html` | Die ältere Fassung als Claude-Artifact. Läuft weiter, teilt aber nur zwischen deinen eigenen Geräten. Kann gelöscht werden, sobald die neue Fassung steht. |

---

## Anmerkungen

**Anmeldung.** E-Mail und Passwort, keine Bestätigungsmails. Die Sitzung bleibt
dauerhaft bestehen — im Alltag meldet ihr euch praktisch nie neu an. Das
Passwort lässt sich in der App unter **Einstellungen → Passwort ändern**
austauschen.

**Passwort vergessen?** Es gibt bewusst keine „Passwort vergessen"-Funktion, die
würde wieder E-Mails brauchen. Stattdessen: In Supabase unter **Authentication →
Users** den betroffenen Benutzer löschen, dann in der App neu anlegen und mit
dem Einladungscode wieder in den Haushalt holen. Die Daten des Haushalts bleiben
dabei unangetastet, solange noch eine zweite Person Mitglied ist.

**Offline.** Die App zeigt die zuletzt geladenen Zahlen aus einem
Zwischenspeicher an, wenn keine Verbindung besteht. Eintragen geht offline
nicht — der Punkt oben rechts wird rot und du bekommst eine Meldung. Es wird
nichts still verschluckt.

**Kategorie gelöscht.** Bereits erfasste Ausgaben behalten ihren Betrag und
erscheinen dann unter „Ohne Kategorie". Nichts geht verloren.

**Sicherung.** Der CSV-Export unter **Einstellungen → Daten** gibt euch
jederzeit eine vollständige Kopie für Excel oder das Archiv.

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

### 4. Anmelde-Adressen freischalten

Damit der Anmeldelink aus der E-Mail funktioniert, muss Supabase die Adresse
deiner Seite kennen.

**Project Settings** → **Authentication** → **URL Configuration**:

- **Site URL**: die Adresse, unter der die App später läuft
  (z. B. `https://DEINNAME.github.io/Haushaltsbuch/`)
- **Redirect URLs**: dieselbe Adresse eintragen, und fürs lokale Testen
  zusätzlich `http://localhost:8777/`

Fertig. Beim ersten Öffnen legst du einen Haushalt an und kannst über
**Einstellungen → Zweite Person einladen** einen Code erzeugen.

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

1. Du legst den Haushalt an.
2. **Einstellungen → Zweite Person einladen** → Code erscheint (14 Tage gültig).
3. Den Code weitergeben — Zettel, Signal, wie ihr wollt.
4. Die zweite Person öffnet dieselbe Adresse, meldet sich mit **ihrer eigenen**
   E-Mail an und trägt den Code unter „Einer Einladung folgen" ein.

Ab dann seht ihr dieselben Zahlen, jeder mit eigenem Login.

---

## Was in welcher Datei steckt

| Datei | Zweck |
|---|---|
| `index.html` | Die komplette App — Oberfläche, Berechnung, Datenbankzugriff |
| `config.js` | Deine zwei Supabase-Zugangsdaten |
| `schema.sql` | Tabellen und Zugriffsregeln, einmalig in Supabase ausführen |
| `haushaltsbuch.html` | Die ältere Fassung als Claude-Artifact. Läuft weiter, teilt aber nur zwischen deinen eigenen Geräten. Kann gelöscht werden, sobald die neue Fassung steht. |

---

## Anmerkungen

**Anmeldung ohne Passwort.** Die App verschickt Anmeldelinks per E-Mail. Der
eingebaute Mailversand von Supabase ist auf wenige Nachrichten pro Stunde
begrenzt — für zwei Personen, die sich selten neu anmelden, reicht das. Die
Sitzung bleibt danach dauerhaft bestehen.

**Offline.** Die App zeigt die zuletzt geladenen Zahlen aus einem
Zwischenspeicher an, wenn keine Verbindung besteht. Eintragen geht offline
nicht — der Punkt oben rechts wird rot und du bekommst eine Meldung. Es wird
nichts still verschluckt.

**Kategorie gelöscht.** Bereits erfasste Ausgaben behalten ihren Betrag und
erscheinen dann unter „Ohne Kategorie". Nichts geht verloren.

**Sicherung.** Der CSV-Export unter **Einstellungen → Daten** gibt euch
jederzeit eine vollständige Kopie für Excel oder das Archiv.

// ============================================================================
//  beleg-lesen — liest einen fotografierten Kassenzettel aus
//
//  Warum diese Funktion überhaupt existiert: Die App ist eine statische Seite.
//  Der Supabase-anon-key darf öffentlich im Browser stehen, ein KI-API-Schlüssel
//  niemals. Also läuft der Aufruf hier, serverseitig, wo der Schlüssel als
//  Secret liegt und nie zum Browser gelangt.
//
//  Einmalig einrichten:
//    supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//    supabase functions deploy beleg-lesen
//
//  Die Funktion prüft den Supabase-Login (verify_jwt ist standardmäßig an).
//  Ohne Anmeldung kommt niemand dran und kann auf deine Rechnung lesen lassen.
// ============================================================================

// Haiku 4.5 ist für diese Aufgabe gewählt: ein Bild, ein kurzes Ergebnis, kein
// Nachdenken nötig — das kostet rund 0,3 Cent pro Beleg. Wenn zerknitterte oder
// sehr lange Bons schlecht erkannt werden, ist "claude-opus-5-5" die stärkere
// Alternative; dann kostet ein Beleg etwa 1,5 Cent. Nur diese Zeile ändern.
const MODELL = "claude-haiku-4-5";

const MAX_BILD_BYTES = 6 * 1024 * 1024;   // ~6 MB, die App schickt normal < 400 KB

const cors = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const antwort = (daten: unknown, status = 200) =>
  new Response(JSON.stringify(daten), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST")    return antwort({ fehler: "Nur POST." }, 405);

  const schluessel = Deno.env.get("ANTHROPIC_API_KEY");
  if (!schluessel) return antwort({ fehler: "Auf dem Server fehlt der API-Schlüssel." }, 500);

  let body: { bild?: string; typ?: string; kategorien?: string[]; heute?: string };
  try { body = await req.json(); }
  catch { return antwort({ fehler: "Ungültige Anfrage." }, 400); }

  const bild = String(body.bild || "");
  if (!bild) return antwort({ fehler: "Kein Bild empfangen." }, 400);
  // base64 bläht um ~4/3 auf — so schätzen wir die echte Bildgröße
  if (bild.length * 0.75 > MAX_BILD_BYTES) return antwort({ fehler: "Das Bild ist zu groß." }, 413);

  const typ = ["image/jpeg", "image/png", "image/webp"].includes(String(body.typ))
    ? String(body.typ) : "image/jpeg";

  // Die Kategorien kommen aus dem Haushalt des Nutzers. Als enum im Schema
  // erzwungen — so kann das Modell gar keinen Namen erfinden, den es in der
  // App nicht gibt. "Unklar" ist der Ausweg, wenn nichts davon passt.
  const kategorien = (Array.isArray(body.kategorien) ? body.kategorien : [])
    .map((k) => String(k).slice(0, 80)).filter(Boolean).slice(0, 40);
  const auswahl = [...kategorien, "Unklar"];

  const heute = /^\d{4}-\d{2}-\d{2}$/.test(String(body.heute || "")) ? String(body.heute) : null;

  const schema = {
    type: "object",
    additionalProperties: false,
    required: ["lesbar", "betrag", "haendler", "datum", "kategorie"],
    properties: {
      lesbar:    { type: "boolean" },
      betrag:    { anyOf: [{ type: "number" }, { type: "null" }] },
      haendler:  { anyOf: [{ type: "string" }, { type: "null" }] },
      datum:     { anyOf: [{ type: "string", format: "date" }, { type: "null" }] },
      kategorie: { type: "string", enum: auswahl },
    },
  };

  const anweisung = [
    "Du liest deutsche Kassenzettel aus. Gib nur die geforderten Felder zurück.",
    "",
    "betrag: der Endbetrag, den der Kunde tatsächlich bezahlt hat. Auf deutschen",
    "Bons steht der bei SUMME, GESAMT, ZU ZAHLEN oder Total. Nimm NICHT die Zeile",
    "'Gegeben'/'Bar', NICHT 'Rückgeld', NICHT einen Zwischenbetrag und NICHT die",
    "MwSt-Zeile. Als Zahl mit Punkt als Dezimaltrenner, also 67.43 statt 67,43.",
    "",
    "datum: das Kaufdatum vom Bon als JJJJ-MM-TT." +
      (heute ? " Heute ist " + heute + "; ein Datum weit in der Zukunft ist falsch gelesen." : ""),
    "",
    "haendler: der Name des Geschäfts, kurz und lesbar — 'REWE', nicht die",
    "vollständige Firmierung mit Rechtsform und Anschrift.",
    "",
    "kategorie: wähle aus der vorgegebenen Liste die, die zum Geschäft und zum",
    "Einkauf am besten passt. Wenn nichts erkennbar passt, nimm 'Unklar' —",
    "lieber 'Unklar' als geraten, der Mensch bestätigt ohnehin.",
    "",
    "lesbar: false, wenn das Foto kein Kassenzettel ist oder so unscharf, dass du",
    "den Betrag nicht sicher lesen kannst. Dann dürfen die anderen Felder null sein.",
  ].join("\n");

  let api: Response;
  try {
    api = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type":      "application/json",
        "x-api-key":         schluessel,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODELL,
        max_tokens: 400,
        system: anweisung,
        output_config: { format: { type: "json_schema", schema } },
        messages: [{
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: typ, data: bild } },
            { type: "text",  text: "Lies diesen Kassenzettel aus." },
          ],
        }],
      }),
    });
  } catch {
    return antwort({ fehler: "Der Lesedienst ist gerade nicht erreichbar." }, 502);
  }

  if (!api.ok) {
    const text = await api.text();
    console.error("Anthropic " + api.status + ": " + text.slice(0, 500));
    // Den Grund bewusst nicht durchreichen — er kann Kontoangaben enthalten.
    const grund = api.status === 429 ? "Zu viele Anfragen, bitte kurz warten."
                : api.status === 401 ? "Der API-Schlüssel auf dem Server stimmt nicht."
                : "Der Beleg konnte nicht gelesen werden.";
    return antwort({ fehler: grund }, 502);
  }

  const daten = await api.json();

  // Ein Sicherheitsnetz: bei stop_reason "refusal" oder "max_tokens" hält sich
  // die Antwort nicht ans Schema, dann ist content kein verwertbares JSON.
  if (daten.stop_reason === "refusal") return antwort({ fehler: "Dieses Bild wurde nicht gelesen." }, 422);

  const text = (daten.content || []).filter((b: { type: string }) => b.type === "text")
    .map((b: { text: string }) => b.text).join("");

  let ergebnis: Record<string, unknown>;
  try { ergebnis = JSON.parse(text); }
  catch { return antwort({ fehler: "Der Beleg konnte nicht gelesen werden." }, 502); }

  if (!ergebnis.lesbar || typeof ergebnis.betrag !== "number" || !isFinite(ergebnis.betrag)) {
    return antwort({ lesbar: false, fehler: "Auf dem Foto war kein Betrag zu erkennen." });
  }

  return antwort({
    lesbar:    true,
    betrag:    Math.abs(ergebnis.betrag),
    haendler:  typeof ergebnis.haendler === "string" ? ergebnis.haendler.slice(0, 80) : null,
    datum:     typeof ergebnis.datum === "string" ? ergebnis.datum : null,
    kategorie: ergebnis.kategorie === "Unklar" ? null : ergebnis.kategorie,
  });
});

// ============================================================================
//  Hier die zwei Werte aus deinem Supabase-Projekt eintragen.
//  Zu finden unter:  Project Settings → API
//
//    HB_SUPABASE_URL       = "Project URL"
//    HB_SUPABASE_ANON_KEY  = "anon public"   (NICHT der service_role key!)
//
//  Der anon key ist dafür gemacht, öffentlich im Browser zu stehen — er darf
//  in ein öffentliches Repository. Geschützt werden die Daten nicht durch
//  Geheimhaltung dieses Schlüssels, sondern durch die Zugriffsregeln in
//  schema.sql: Ohne Anmeldung und ohne Mitgliedschaft im Haushalt sind alle
//  Tabellen leer.
//
//  Der service_role key umgeht dagegen ALLE Zugriffsregeln. Der gehört
//  niemals in diese Datei und niemals in ein Repository.
// ============================================================================

window.HB_CONFIG = {
  url:     "",
  anonKey: ""
};

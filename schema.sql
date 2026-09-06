-- ============================================================================
--  Haushaltsbuch — Datenbankschema für Supabase
--  Einmal komplett in den SQL-Editor von Supabase einfügen und ausführen.
--  Das Skript ist wiederholbar: ein zweiter Lauf richtet keinen Schaden an.
-- ============================================================================

-- ---------------------------------------------------------------- Tabellen --

create table if not exists public.households (
  id          uuid primary key default gen_random_uuid(),
  name        text not null default 'Unser Haushalt',
  goal        numeric(12,2) not null default 0,      -- Sparziel pro Monat
  people      text[] not null default '{}',          -- Namen für "wer hat gezahlt"
  created_at  timestamptz not null default now()
);

create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  joined_at    timestamptz not null default now(),
  primary key (household_id, user_id)
);

create table if not exists public.categories (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name         text not null,
  color_index  smallint not null default 0,          -- 0–7, Farbslot in der App
  position     smallint not null default 0
);

-- Monatlich wiederkehrende Posten: Einnahmen und feste Ausgaben in einer Tabelle.
create table if not exists public.plan_items (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  kind         text not null check (kind in ('income','fixed')),
  name         text not null,
  amount       numeric(12,2) not null default 0,
  category_id  uuid references public.categories(id) on delete set null,
  person       text,                                 -- nur bei kind='income'
  due_day      smallint,                             -- nur bei kind='fixed', 1–31
  valid_from   text,                                 -- 'YYYY-MM' oder NULL = schon immer
  valid_to     text,                                 -- 'YYYY-MM' oder NULL = unbefristet
  created_at   timestamptz not null default now()
);

create table if not exists public.expenses (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  spent_on     date not null,
  amount       numeric(12,2) not null,
  category_id  uuid references public.categories(id) on delete set null,
  note         text,
  person       text,
  created_at   timestamptz not null default now(),
  created_by   uuid default auth.uid()
);

-- Einladungscodes, mit denen die zweite Person dem Haushalt beitritt.
create table if not exists public.invites (
  code         text primary key,
  household_id uuid not null references public.households(id) on delete cascade,
  created_by   uuid not null default auth.uid(),
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default now() + interval '14 days'
);

create index if not exists expenses_household_date_idx on public.expenses (household_id, spent_on);
create index if not exists plan_items_household_idx    on public.plan_items (household_id);
create index if not exists categories_household_idx    on public.categories (household_id);
create index if not exists members_user_idx            on public.household_members (user_id);

-- ------------------------------------------------------------ Hilfsfunktion --
-- Eine Regel auf household_members, die household_members abfragt, würde sich
-- selbst endlos aufrufen. security definer umgeht die Regelprüfung und bricht
-- diese Schleife — deshalb steht hier genau eine, eng begrenzte Abfrage.

create or replace function public.is_member(h uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.household_members m
    where m.household_id = h and m.user_id = auth.uid()
  );
$$;

revoke all on function public.is_member(uuid) from public;
grant execute on function public.is_member(uuid) to authenticated;

-- ------------------------------------------------------------ Zugriffsregeln --
-- Grundsatz: Man sieht und ändert ausschließlich Daten von Haushalten, in denen
-- man Mitglied ist. Ohne Mitgliedschaft sind alle Tabellen leer, nicht bloß
-- schreibgeschützt.

alter table public.households        enable row level security;
alter table public.household_members enable row level security;
alter table public.categories        enable row level security;
alter table public.plan_items        enable row level security;
alter table public.expenses          enable row level security;
alter table public.invites           enable row level security;

drop policy if exists households_select on public.households;
drop policy if exists households_update on public.households;
create policy households_select on public.households
  for select to authenticated using (public.is_member(id));
create policy households_update on public.households
  for update to authenticated using (public.is_member(id)) with check (public.is_member(id));
-- Angelegt wird ein Haushalt nur über create_household(), nie direkt:
-- so kann keine Zeile ohne zugehörige Mitgliedschaft entstehen.

drop policy if exists members_select on public.household_members;
drop policy if exists members_delete on public.household_members;
create policy members_select on public.household_members
  for select to authenticated using (public.is_member(household_id));
create policy members_delete on public.household_members
  for delete to authenticated using (user_id = auth.uid());
-- Beigetreten wird nur über join_household(code).

drop policy if exists categories_all on public.categories;
create policy categories_all on public.categories
  for all to authenticated using (public.is_member(household_id)) with check (public.is_member(household_id));

drop policy if exists plan_items_all on public.plan_items;
create policy plan_items_all on public.plan_items
  for all to authenticated using (public.is_member(household_id)) with check (public.is_member(household_id));

drop policy if exists expenses_all on public.expenses;
create policy expenses_all on public.expenses
  for all to authenticated using (public.is_member(household_id)) with check (public.is_member(household_id));

drop policy if exists invites_select on public.invites;
drop policy if exists invites_delete on public.invites;
create policy invites_select on public.invites
  for select to authenticated using (public.is_member(household_id));
create policy invites_delete on public.invites
  for delete to authenticated using (public.is_member(household_id));
-- Ein Code wird nur über create_invite() erzeugt und über join_household()
-- eingelöst. Wer den Code hat, ist noch kein Mitglied und darf die Tabelle
-- daher nicht selbst lesen — sonst könnte man fremde Codes durchprobieren.

-- ------------------------------------------------------------------- Abläufe --

-- Haushalt anlegen: Haushalt, eigene Mitgliedschaft und Standardkategorien
-- entstehen gemeinsam oder gar nicht.
create or replace function public.create_household(p_name text default 'Unser Haushalt')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare h uuid;
begin
  if auth.uid() is null then
    raise exception 'Nicht angemeldet';
  end if;

  insert into public.households (name)
  values (coalesce(nullif(btrim(p_name), ''), 'Unser Haushalt'))
  returning id into h;

  insert into public.household_members (household_id, user_id) values (h, auth.uid());

  insert into public.categories (household_id, name, color_index, position) values
    (h, 'Lebensmittel',    0, 0),
    (h, 'Wohnen',          1, 1),
    (h, 'Mobilität',       2, 2),
    (h, 'Freizeit',        3, 3),
    (h, 'Gesundheit',      4, 4),
    (h, 'Versicherungen',  5, 5),
    (h, 'Abos & Verträge', 6, 6),
    (h, 'Sonstiges',       7, 7);

  return h;
end $$;

-- Einladungscode erzeugen. Alphabet ohne 0/O und 1/I/L, damit beim Abtippen
-- oder Vorlesen nichts verwechselt wird.
create or replace function public.create_invite(p_household uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  c text;
  i int;
begin
  if not public.is_member(p_household) then
    raise exception 'Kein Zugriff auf diesen Haushalt';
  end if;

  for attempt in 1..10 loop
    c := '';
    for i in 1..8 loop
      c := c || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    begin
      insert into public.invites (code, household_id) values (c, p_household);
      return c;
    exception when unique_violation then
      -- Code war schon vergeben, nächster Versuch
    end;
  end loop;

  raise exception 'Konnte keinen freien Einladungscode erzeugen';
end $$;

-- Einladung einlösen. Läuft mit erhöhten Rechten, weil die beitretende Person
-- noch kein Mitglied ist und die invites-Tabelle selbst nicht lesen darf.
create or replace function public.join_household(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare inv public.invites%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Nicht angemeldet';
  end if;

  select * into inv from public.invites
  where code = upper(btrim(p_code));

  if not found then
    raise exception 'Dieser Einladungscode ist unbekannt';
  end if;
  if inv.expires_at < now() then
    raise exception 'Dieser Einladungscode ist abgelaufen';
  end if;

  insert into public.household_members (household_id, user_id)
  values (inv.household_id, auth.uid())
  on conflict do nothing;

  return inv.household_id;
end $$;

revoke all on function public.create_household(text) from public;
revoke all on function public.create_invite(uuid)    from public;
revoke all on function public.join_household(text)   from public;
grant execute on function public.create_household(text) to authenticated;
grant execute on function public.create_invite(uuid)    to authenticated;
grant execute on function public.join_household(text)   to authenticated;

-- --------------------------------------------------------------- Live-Updates --
-- Damit beide Geräte Änderungen sofort sehen, ohne neu zu laden.

do $$
begin
  alter publication supabase_realtime add table public.expenses;
exception when others then null; end $$;
do $$
begin
  alter publication supabase_realtime add table public.plan_items;
exception when others then null; end $$;
do $$
begin
  alter publication supabase_realtime add table public.categories;
exception when others then null; end $$;
do $$
begin
  alter publication supabase_realtime add table public.households;
exception when others then null; end $$;

-- ------------------------------------------------- Nachtrag: Rechte enger --
-- Supabase vergibt per Voreinstellung Ausführungsrechte auf Funktionen im
-- public-Schema auch an die Rolle anon (nicht angemeldete Besucher). Die
-- Funktionen oben prüfen zwar selbst, ob jemand angemeldet und Mitglied ist —
-- aber wer nicht angemeldet ist, soll sie gar nicht erst betreten können.

revoke execute on function public.is_member(uuid)          from anon;
revoke execute on function public.create_household(text)   from anon;
revoke execute on function public.create_invite(uuid)      from anon;
revoke execute on function public.join_household(text)     from anon;

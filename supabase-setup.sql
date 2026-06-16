-- ============================================================
--  Prode Argento — setup de Supabase
--  Pegá TODO esto en:  Supabase → SQL Editor → New query → Run
-- ============================================================

-- Predicciones de cada jugador: una fila por (usuario, partido)
create table if not exists public.picks (
  username   text not null,
  match_id   text not null,
  home       int  not null default 0,   -- goles del equipo de la IZQUIERDA en pantalla
  away       int  not null default 0,   -- goles del equipo de la DERECHA en pantalla
  updated_at timestamptz not null default now(),
  primary key (username, match_id)
);

-- Resultados reales (los carga el admin): una fila por partido
create table if not exists public.results (
  match_id   text primary key,
  home       int not null,
  away       int not null,
  updated_at timestamptz not null default now()
);

-- Reclamos del bono por participar: una fila por usuario que lo reclamó
create table if not exists public.claims (
  username   text primary key,
  claimed_at timestamptz not null default now()
);

-- ------------------------------------------------------------
--  Permisos (RLS)
--  Prode casual: se permite leer/escribir con la anon key.
--  El "modo admin" se gatea en la app con la clave de la URL
--  (no a nivel base). Suficiente para un prode entre conocidos.
-- ------------------------------------------------------------
alter table public.picks   enable row level security;
alter table public.results enable row level security;
alter table public.claims  enable row level security;

drop policy if exists picks_all on public.picks;
create policy picks_all on public.picks
  for all to anon using (true) with check (true);

drop policy if exists results_all on public.results;
create policy results_all on public.results
  for all to anon using (true) with check (true);

drop policy if exists claims_all on public.claims;
create policy claims_all on public.claims
  for all to anon using (true) with check (true);

-- ------------------------------------------------------------
--  (Opcional) Realtime: que el resultado cargado por el admin
--  aparezca al INSTANTE en todos sin esperar el refresco (~30s).
--  Si tira "already member of publication", ya estaba: ignoralo.
-- ------------------------------------------------------------
alter publication supabase_realtime add table public.results;

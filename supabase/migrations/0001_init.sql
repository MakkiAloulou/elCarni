-- elCarni — schéma initial Supabase.
-- Reflète le modèle en mémoire de lib/models/models.dart, plus la table
-- teachers (auth + statut d'approbation) qui n'existe pas encore côté Dart.
-- À coller dans Supabase → SQL Editor, une fois le projet créé.

-- ---------------------------------------------------------------------
-- Enums — mêmes valeurs que lib/models/models.dart, en snake_case.
-- ---------------------------------------------------------------------

create type teacher_status as enum ('new', 'valid', 'renew');
create type level as enum ('septieme', 'huitieme', 'neuvieme', 'premiere', 'deuxieme', 'troisieme', 'bac');
create type section as enum ('maths', 'sciences_exp', 'technique', 'info', 'eco', 'lettres');
create type session_status as enum ('scheduled', 'done', 'cancelled');
create type attendance_status as enum ('present', 'absent_justified', 'absent_unjustified');

-- ---------------------------------------------------------------------
-- teachers — une ligne par utilisateur Google authentifié.
-- id = auth.users.id, créée automatiquement au premier login (trigger
-- plus bas). status contrôle l'accès : 'new' et 'renew' voient un écran
-- d'attente côté app, et sont aussi bloqués ici par les policies RLS.
-- ---------------------------------------------------------------------

create table public.teachers (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  name text not null default '',
  subject text,
  status teacher_status not null default 'new',
  created_at timestamptz not null default now()
);

alter table public.teachers enable row level security;

-- Un prof peut voir/modifier sa propre ligne (mais pas changer son
-- propre status — ça reste réservé au dashboard Supabase pour l'instant).
create policy "teachers select own" on public.teachers
  for select using (id = auth.uid());

create policy "teachers update own (no status)" on public.teachers
  for update using (id = auth.uid())
  with check (id = auth.uid() and status = (select status from public.teachers where id = auth.uid()));

-- ---------------------------------------------------------------------
-- Création automatique de la ligne teacher au premier login Google.
-- ---------------------------------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.teachers (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- Helper RLS — vrai seulement pour un teacher validé. Centralise la
-- règle "new/renew ne touchent aucune donnée métier" pour ne pas la
-- répéter dans chaque policy.
-- ---------------------------------------------------------------------

create function public.is_valid_teacher()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.teachers
    where id = auth.uid() and status = 'valid'
  );
$$;

-- ---------------------------------------------------------------------
-- groups
-- ---------------------------------------------------------------------

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.teachers (id) on delete cascade,
  level level not null,
  section section,
  group_number int,
  note text,
  price_per_session numeric(10, 2) not null,
  weekday int not null check (weekday between 0 and 6),
  start_time time not null,
  duration_minutes int not null default 120,
  created_at timestamptz not null default now()
);

alter table public.groups enable row level security;

create policy "groups owner" on public.groups
  for all using (teacher_id = auth.uid() and public.is_valid_teacher())
  with check (teacher_id = auth.uid() and public.is_valid_teacher());

-- ---------------------------------------------------------------------
-- students
-- ---------------------------------------------------------------------

create table public.students (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.teachers (id) on delete cascade,
  name text not null,
  phone text,
  parent_phone text,
  class_level level,
  class_section section,
  class_number int,
  school text,
  is_free boolean not null default false,
  suspended_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.students enable row level security;

create policy "students owner" on public.students
  for all using (teacher_id = auth.uid() and public.is_valid_teacher())
  with check (teacher_id = auth.uid() and public.is_valid_teacher());

-- ---------------------------------------------------------------------
-- enrollments — élève <-> groupe, historisée.
-- ---------------------------------------------------------------------

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  group_id uuid not null references public.groups (id) on delete cascade,
  joined_at date not null,
  left_at date
);

alter table public.enrollments enable row level security;

create policy "enrollments owner" on public.enrollments
  for all using (
    public.is_valid_teacher()
    and exists (select 1 from public.groups g where g.id = group_id and g.teacher_id = auth.uid())
  )
  with check (
    public.is_valid_teacher()
    and exists (select 1 from public.groups g where g.id = group_id and g.teacher_id = auth.uid())
  );

-- ---------------------------------------------------------------------
-- sessions — prix figé à la création, voir README §2.
-- ---------------------------------------------------------------------

create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  date date not null,
  start_time time,
  is_rescheduled boolean not null default false,
  status session_status not null default 'scheduled',
  price numeric(10, 2) not null
);

alter table public.sessions enable row level security;

create policy "sessions owner" on public.sessions
  for all using (
    public.is_valid_teacher()
    and exists (select 1 from public.groups g where g.id = group_id and g.teacher_id = auth.uid())
  )
  with check (
    public.is_valid_teacher()
    and exists (select 1 from public.groups g where g.id = group_id and g.teacher_id = auth.uid())
  );

-- ---------------------------------------------------------------------
-- attendances
-- ---------------------------------------------------------------------

create table public.attendances (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  status attendance_status not null,
  unique (session_id, student_id)
);

alter table public.attendances enable row level security;

create policy "attendances owner" on public.attendances
  for all using (
    public.is_valid_teacher()
    and exists (
      select 1 from public.sessions s
      join public.groups g on g.id = s.group_id
      where s.id = session_id and g.teacher_id = auth.uid()
    )
  )
  with check (
    public.is_valid_teacher()
    and exists (
      select 1 from public.sessions s
      join public.groups g on g.id = s.group_id
      where s.id = session_id and g.teacher_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- payments — rattachés à l'élève seul, jamais à un groupe.
-- ---------------------------------------------------------------------

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  amount numeric(10, 2) not null,
  paid_at date not null,
  sessions_covered int not null default 4,
  note text
);

alter table public.payments enable row level security;

create policy "payments owner" on public.payments
  for all using (
    public.is_valid_teacher()
    and exists (select 1 from public.students st where st.id = student_id and st.teacher_id = auth.uid())
  )
  with check (
    public.is_valid_teacher()
    and exists (select 1 from public.students st where st.id = student_id and st.teacher_id = auth.uid())
  );

-- ---------------------------------------------------------------------
-- Index de base sur les FK les plus interrogées.
-- ---------------------------------------------------------------------

create index groups_teacher_id_idx on public.groups (teacher_id);
create index students_teacher_id_idx on public.students (teacher_id);
create index enrollments_student_id_idx on public.enrollments (student_id);
create index enrollments_group_id_idx on public.enrollments (group_id);
create index sessions_group_id_idx on public.sessions (group_id);
create index attendances_session_id_idx on public.attendances (session_id);
create index attendances_student_id_idx on public.attendances (student_id);
create index payments_student_id_idx on public.payments (student_id);

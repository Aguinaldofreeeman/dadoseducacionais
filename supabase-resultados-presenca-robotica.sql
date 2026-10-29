-- Estrutura e permissões para os importadores CSV de Aluno Presente e Robótica.
-- Execute uma vez no Supabase Dashboard > SQL Editor.

create table if not exists public.resultados_presenca (
  id uuid primary key default gen_random_uuid(),
  periodo text not null,
  periodo_label text not null,
  escola text not null,
  codigo_escola text not null,
  pei integer not null default 0,
  matriculas_ativas integer,
  presenca numeric,
  evolucao_presenca numeric,
  aulas_previstas integer,
  aulas_dadas numeric,
  evolucao_aulas numeric,
  total_turmas integer,
  total_matrizes integer,
  tipo_escola text,
  supervisor text,
  created_at timestamptz not null default now(),
  unique (periodo, codigo_escola)
);

create index if not exists resultados_presenca_periodo_idx
  on public.resultados_presenca (periodo, escola);

alter table public.resultados_presenca enable row level security;

drop policy if exists "Select autenticado em resultados_presenca" on public.resultados_presenca;
create policy "Select autenticado em resultados_presenca" on public.resultados_presenca
  for select to authenticated using (true);

drop policy if exists "Insert apenas ADM em resultados_presenca" on public.resultados_presenca;
create policy "Insert apenas ADM em resultados_presenca" on public.resultados_presenca
  for insert to authenticated with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Delete apenas ADM em resultados_presenca" on public.resultados_presenca;
create policy "Delete apenas ADM em resultados_presenca" on public.resultados_presenca
  for delete to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

grant select, insert, delete on public.resultados_presenca to authenticated;

create table if not exists public.resultados_robotica (
  id uuid primary key default gen_random_uuid(),
  escola text not null,
  codigo_escola text not null unique,
  mat integer not null,
  pub integer not null,
  rasc integer not null,
  corr integer not null,
  dev integer not null,
  conc integer not null,
  acerto numeric not null,
  indice numeric not null,
  nota numeric not null,
  created_at timestamptz not null default now()
);

alter table public.resultados_robotica enable row level security;

drop policy if exists "Select autenticado em resultados_robotica" on public.resultados_robotica;
create policy "Select autenticado em resultados_robotica" on public.resultados_robotica
  for select to authenticated using (true);

drop policy if exists "Insert apenas ADM em resultados_robotica" on public.resultados_robotica;
create policy "Insert apenas ADM em resultados_robotica" on public.resultados_robotica
  for insert to authenticated with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Delete apenas ADM em resultados_robotica" on public.resultados_robotica;
create policy "Delete apenas ADM em resultados_robotica" on public.resultados_robotica
  for delete to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

grant select, insert, delete on public.resultados_robotica to authenticated;

notify pgrst, 'reload schema';

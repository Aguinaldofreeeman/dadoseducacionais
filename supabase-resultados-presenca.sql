-- Estrutura e permissões do importador e painel de Aluno Presente.
-- Execute no SQL Editor do projeto Supabase configurado em config.js.

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

create unique index if not exists resultados_presenca_periodo_codigo_escola_uidx
  on public.resultados_presenca (periodo, codigo_escola);

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

drop policy if exists "Update apenas ADM em resultados_presenca" on public.resultados_presenca;
create policy "Update apenas ADM em resultados_presenca" on public.resultados_presenca
  for update to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  ) with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

grant select, insert, update on public.resultados_presenca to authenticated;

notify pgrst, 'reload schema';

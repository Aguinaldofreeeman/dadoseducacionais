-- Estrutura e permissões do importador e painel de Apoio Presencial.
-- Execute no SQL Editor do projeto Supabase configurado em config.js.

create table if not exists public.resultados_apoio_presencial (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  periodo text not null,
  escola text not null,
  codigo_escola text not null,
  apoios integer,
  nao_finalizados integer,
  apoiados integer,
  professores integer,
  avaliadores integer,
  equipe_gestora integer,
  indice numeric,
  filtros text,
  created_at timestamptz not null default now(),
  unique (ano, periodo, codigo_escola)
);

create index if not exists resultados_apoio_presencial_ano_periodo_idx
  on public.resultados_apoio_presencial (ano, periodo);

create unique index if not exists resultados_apoio_presencial_ano_periodo_codigo_uidx
  on public.resultados_apoio_presencial (ano, periodo, codigo_escola);

alter table public.resultados_apoio_presencial enable row level security;

drop policy if exists "Select autenticado em resultados_apoio_presencial" on public.resultados_apoio_presencial;
drop policy if exists "Select público em resultados_apoio_presencial" on public.resultados_apoio_presencial;
create policy "Select público em resultados_apoio_presencial" on public.resultados_apoio_presencial
  for select to anon, authenticated using (true);

drop policy if exists "Insert apenas ADM em resultados_apoio_presencial" on public.resultados_apoio_presencial;
create policy "Insert apenas ADM em resultados_apoio_presencial" on public.resultados_apoio_presencial
  for insert to authenticated with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Update apenas ADM em resultados_apoio_presencial" on public.resultados_apoio_presencial;
create policy "Update apenas ADM em resultados_apoio_presencial" on public.resultados_apoio_presencial
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

grant select on public.resultados_apoio_presencial to anon, authenticated;
grant insert, update on public.resultados_apoio_presencial to authenticated;

notify pgrst, 'reload schema';

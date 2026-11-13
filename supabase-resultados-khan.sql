-- Cria a estrutura usada pelo painel khan.html e pelo importador mensal da Khan Academy em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.
-- A chave (ano, mes, codigo_escola) preserva o historico mensal: reimportar um mes
-- substitui apenas os registros daquele ano/mes.

create table if not exists public.resultados_khan (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  mes integer not null check (mes between 1 and 12),
  codigo_escola text not null,
  escola text not null,
  matriculas_ativas integer,
  alunos_ativos integer,
  alunos_com_atividades integer,
  percentual_alunos_ativos numeric,
  tempo_total_minutos numeric,
  tempo_por_aluno_minutos numeric,
  atividades_realizadas integer,
  atividades_acertadas integer,
  habilidades_com_progresso numeric,
  indice_atividades_por_aluno numeric,
  fonte_arquivo text,
  created_at timestamptz not null default now(),
  constraint resultados_khan_ano_mes_codigo_key unique (ano, mes, codigo_escola)
);

create index if not exists resultados_khan_ano_mes_idx
  on public.resultados_khan (ano, mes);

alter table public.resultados_khan enable row level security;

drop policy if exists "Select publico em resultados_khan" on public.resultados_khan;
create policy "Select publico em resultados_khan"
  on public.resultados_khan
  for select to anon, authenticated using (true);

drop policy if exists "Insert apenas ADM em resultados_khan" on public.resultados_khan;
create policy "Insert apenas ADM em resultados_khan"
  on public.resultados_khan
  for insert to authenticated
  with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Delete apenas ADM em resultados_khan" on public.resultados_khan;
create policy "Delete apenas ADM em resultados_khan"
  on public.resultados_khan
  for delete to authenticated
  using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select on public.resultados_khan to anon, authenticated;
grant insert, delete on public.resultados_khan to authenticated;

notify pgrst, 'reload schema';

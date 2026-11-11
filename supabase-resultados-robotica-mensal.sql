-- Cria a estrutura usada pelo painel robotica-mensal.html e pelo importador
-- mensal de Robótica em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.
--
-- A chave (ano, mes, codigo_escola) preserva o histórico mensal: reimportar
-- um mês substitui apenas os registros daquele ano/mês, sem apagar os demais.
-- A coluna semanas guarda quantas semanas letivas o mês teve e é usada pelo
-- índice de atividades por aluno (concluídas ÷ alunos ativos ÷ semanas).

create table if not exists public.resultados_robotica_mensal (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  mes integer not null check (mes between 1 and 12),
  codigo_escola text not null,
  escola text not null,
  semanas integer not null default 4 check (semanas between 1 and 6),
  mat integer,
  pub integer,
  rasc integer default 0,
  corr integer default 0,
  dev integer default 0,
  conc integer,
  acerto numeric,
  indice numeric,
  nota numeric,
  created_at timestamptz default now(),
  unique (ano, mes, codigo_escola)
);

create index if not exists resultados_robotica_mensal_ano_mes_idx
  on public.resultados_robotica_mensal (ano, mes);

alter table public.resultados_robotica_mensal enable row level security;

-- Leitura pública: o painel robotica-mensal.html é acessado sem login.
drop policy if exists "Select público em resultados_robotica_mensal" on public.resultados_robotica_mensal;
create policy "Select público em resultados_robotica_mensal"
  on public.resultados_robotica_mensal
  for select to anon, authenticated using (true);

-- Gravação apenas para administradores ativos (ADM/ADMIN).
drop policy if exists "Insert apenas ADM em resultados_robotica_mensal" on public.resultados_robotica_mensal;
create policy "Insert apenas ADM em resultados_robotica_mensal"
  on public.resultados_robotica_mensal
  for insert to authenticated
  with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Delete apenas ADM em resultados_robotica_mensal" on public.resultados_robotica_mensal;
create policy "Delete apenas ADM em resultados_robotica_mensal"
  on public.resultados_robotica_mensal
  for delete to authenticated
  using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select on public.resultados_robotica_mensal to anon, authenticated;
grant insert, delete on public.resultados_robotica_mensal to authenticated;

notify pgrst, 'reload schema';

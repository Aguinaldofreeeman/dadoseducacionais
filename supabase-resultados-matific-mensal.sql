-- Cria a estrutura usada pelo importador de planilhas mensais do Matific em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.

create table if not exists public.resultados_matific_mensal (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  mes integer not null check (mes between 1 and 12),
  semanas numeric(3,1) not null check (semanas > 0),
  escola text not null,
  total_matriculas integer,
  alunos_ativos_no_periodo integer,
  percentual_alunos_ativos_no_periodo numeric,
  total_de_atividades_iniciadas integer,
  total_de_atividades_concluidas integer,
  indice_de_atividades_concluidas_por_aluno numeric,
  created_at timestamptz default now(),
  unique (ano, mes, escola)
);

alter table public.resultados_matific_mensal enable row level security;

drop policy if exists "Select autenticado em resultados_matific_mensal" on public.resultados_matific_mensal;
create policy "Select autenticado em resultados_matific_mensal" on public.resultados_matific_mensal
  for select to authenticated using (true);

drop policy if exists "Insert autenticado em resultados_matific_mensal" on public.resultados_matific_mensal;
create policy "Insert autenticado em resultados_matific_mensal" on public.resultados_matific_mensal
  for insert to authenticated with check (true);

drop policy if exists "Delete apenas ADM em resultados_matific_mensal" on public.resultados_matific_mensal;
create policy "Delete apenas ADM em resultados_matific_mensal" on public.resultados_matific_mensal
  for delete to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select, insert, delete on public.resultados_matific_mensal to authenticated;

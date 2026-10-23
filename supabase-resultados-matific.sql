-- Cria a estrutura usada pelo importador do Matific em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.

create table if not exists public.resultados_matific (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  escola text not null,
  total_matriculas integer,
  alunos_ativos_no_periodo integer,
  percentual_alunos_ativos_no_periodo numeric,
  total_de_atividades_iniciadas integer,
  total_de_atividades_concluidas integer,
  indice_de_atividades_concluidas_por_aluno numeric,
  created_at timestamptz default now(),
  unique (ano, escola)
);

alter table public.resultados_matific enable row level security;

drop policy if exists "Select autenticado em resultados_matific" on public.resultados_matific;
create policy "Select autenticado em resultados_matific" on public.resultados_matific
  for select to authenticated using (true);

drop policy if exists "Insert autenticado em resultados_matific" on public.resultados_matific;
create policy "Insert autenticado em resultados_matific" on public.resultados_matific
  for insert to authenticated with check (true);

drop policy if exists "Delete apenas ADM em resultados_matific" on public.resultados_matific;
create policy "Delete apenas ADM em resultados_matific" on public.resultados_matific
  for delete to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select, insert, delete on public.resultados_matific to authenticated;

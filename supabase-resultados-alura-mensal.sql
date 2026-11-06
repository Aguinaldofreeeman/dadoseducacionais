-- Cria a estrutura usada pelo importador de planilhas mensais da Alura em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.
-- A chave (ano, mes, escola) preserva o histórico mensal: reimportar um mês
-- substitui apenas os registros daquele ano/mês.

create table if not exists public.resultados_alura_mensal (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  mes integer not null check (mes between 1 and 12),
  escola text not null,
  matriculas_ativas integer,
  alunos_com_acessos_no_periodo integer,
  indice_de_acessos_no_periodo numeric,
  total_de_exercicios_realizados integer,
  quantidade_media_de_tentativas_por_exercicio numeric,
  indice_de_exercicios_corretos_ate_2a_tentativa numeric,
  media_das_avaliacoes_mensais_entre_alunos_que_nao_zeraram numeric,
  media_das_avaliacoes_mensais numeric,
  indice_de_realizacao_das_avaliacoes_mensais numeric,
  media_nas_questoes_discursivas numeric,
  created_at timestamptz default now(),
  unique (ano, mes, escola)
);

alter table public.resultados_alura_mensal enable row level security;

-- Leitura pública: o painel visualizacao-mensal-alura.html é acessado sem login.
drop policy if exists "Select público em resultados_alura_mensal" on public.resultados_alura_mensal;
create policy "Select público em resultados_alura_mensal" on public.resultados_alura_mensal
  for select to anon, authenticated using (true);

drop policy if exists "Insert autenticado em resultados_alura_mensal" on public.resultados_alura_mensal;
create policy "Insert autenticado em resultados_alura_mensal" on public.resultados_alura_mensal
  for insert to authenticated with check (true);

drop policy if exists "Delete apenas ADM em resultados_alura_mensal" on public.resultados_alura_mensal;
create policy "Delete apenas ADM em resultados_alura_mensal" on public.resultados_alura_mensal
  for delete to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select on public.resultados_alura_mensal to anon, authenticated;
grant insert, delete on public.resultados_alura_mensal to authenticated;

notify pgrst, 'reload schema';

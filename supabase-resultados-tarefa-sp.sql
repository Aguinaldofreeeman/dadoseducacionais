-- Cria a estrutura usada pelo painel tarefa-sp.html e pelo importador de Tarefa SP
-- em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.
--
-- A chave (ano, semana_num, codigo_escola) preserva o histórico semanal:
-- reimportar uma semana substitui apenas os registros daquele ano/semana.
-- Leitura pública (o painel não exige login); gravação/exclusão exigem ADM.

create table if not exists public.resultados_tarefa_sp (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  semana_num integer not null,
  semana_label text not null,
  periodo_inicio date,
  periodo_fim date,
  codigo_escola text not null,
  escola text not null,
  matriculas_ativas integer,
  alunos_tarefas integer,
  pct_alunos_tarefas numeric,
  tarefas_propostas integer,
  tarefas_prazo integer,
  tarefas_fora_prazo integer,
  tarefas_incompletas integer,
  tarefas_nao_realizadas integer,
  pct_tarefas_realizadas numeric,
  pct_acertos numeric,
  iq numeric,
  fonte_arquivo text,
  created_at timestamptz not null default now(),
  constraint resultados_tarefa_sp_ano_semana_codigo_key unique (ano, semana_num, codigo_escola)
);

create index if not exists resultados_tarefa_sp_ano_semana_idx
  on public.resultados_tarefa_sp (ano, semana_num);

alter table public.resultados_tarefa_sp enable row level security;

drop policy if exists "Select público em resultados_tarefa_sp" on public.resultados_tarefa_sp;
create policy "Select público em resultados_tarefa_sp"
  on public.resultados_tarefa_sp
  for select to anon, authenticated using (true);

drop policy if exists "Insert apenas ADM em resultados_tarefa_sp" on public.resultados_tarefa_sp;
create policy "Insert apenas ADM em resultados_tarefa_sp"
  on public.resultados_tarefa_sp
  for insert to authenticated
  with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Update apenas ADM em resultados_tarefa_sp" on public.resultados_tarefa_sp;
create policy "Update apenas ADM em resultados_tarefa_sp"
  on public.resultados_tarefa_sp
  for update to authenticated
  using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  )
  with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Delete apenas ADM em resultados_tarefa_sp" on public.resultados_tarefa_sp;
create policy "Delete apenas ADM em resultados_tarefa_sp"
  on public.resultados_tarefa_sp
  for delete to authenticated
  using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select on public.resultados_tarefa_sp to anon, authenticated;
grant insert, update, delete on public.resultados_tarefa_sp to authenticated;

notify pgrst, 'reload schema';

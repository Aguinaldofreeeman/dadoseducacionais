-- Cria a estrutura usada pelo painel leia-sp.html e pelo importador de Leia SP
-- em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.
--
-- A chave (ano, periodo, codigo_escola) preserva o histórico semanal:
-- reimportar uma semana substitui apenas os registros daquele ano/período.
-- Leitura pública (o painel não exige login); gravação/exclusão exigem ADM.

create table if not exists public.resultados_leia_sp (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  periodo text not null,
  periodo_label text,
  codigo_escola text not null,
  escola text not null,
  total_matriculas integer,
  alunos_ativos integer,
  percentual_ativos numeric,
  acerto numeric,
  indice numeric,
  paginas_lidas integer,
  livros_concluidos integer,
  tempo_leitura_min numeric,
  tempo_semanal_por_aluno numeric,
  created_at timestamptz not null default now(),
  constraint resultados_leia_sp_ano_periodo_codigo_key unique (ano, periodo, codigo_escola)
);

create index if not exists resultados_leia_sp_ano_periodo_idx
  on public.resultados_leia_sp (ano, periodo);

alter table public.resultados_leia_sp enable row level security;

drop policy if exists "Select público em resultados_leia_sp" on public.resultados_leia_sp;
create policy "Select público em resultados_leia_sp"
  on public.resultados_leia_sp
  for select to anon, authenticated using (true);

drop policy if exists "Insert apenas ADM em resultados_leia_sp" on public.resultados_leia_sp;
create policy "Insert apenas ADM em resultados_leia_sp"
  on public.resultados_leia_sp
  for insert to authenticated
  with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

drop policy if exists "Update apenas ADM em resultados_leia_sp" on public.resultados_leia_sp;
create policy "Update apenas ADM em resultados_leia_sp"
  on public.resultados_leia_sp
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

drop policy if exists "Delete apenas ADM em resultados_leia_sp" on public.resultados_leia_sp;
create policy "Delete apenas ADM em resultados_leia_sp"
  on public.resultados_leia_sp
  for delete to authenticated
  using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select on public.resultados_leia_sp to anon, authenticated;
grant insert, update, delete on public.resultados_leia_sp to authenticated;

notify pgrst, 'reload schema';

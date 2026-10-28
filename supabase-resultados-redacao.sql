-- Cria a estrutura usada pelo importador da Redação Paulista em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.
-- Uma linha por escola x quinzena; a linha regional usa escola = 'MARILIA'.
-- quinzena = posição da quinzena no ano (1..N); periodo = rótulo exibido (ex.: '11/10 a 17/10').

create table if not exists public.resultados_redacao (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  escola text not null,
  codigo text,
  quinzena integer not null,
  periodo text not null,
  mes text,
  indice numeric,
  nota numeric,
  created_at timestamptz default now(),
  unique (ano, escola, quinzena)
);

create index if not exists resultados_redacao_ano_idx on public.resultados_redacao (ano, quinzena);

alter table public.resultados_redacao enable row level security;

drop policy if exists "Select autenticado em resultados_redacao" on public.resultados_redacao;
create policy "Select autenticado em resultados_redacao" on public.resultados_redacao
  for select to authenticated using (true);

drop policy if exists "Insert autenticado em resultados_redacao" on public.resultados_redacao;
create policy "Insert autenticado em resultados_redacao" on public.resultados_redacao
  for insert to authenticated with check (true);

drop policy if exists "Delete apenas ADM em resultados_redacao" on public.resultados_redacao;
create policy "Delete apenas ADM em resultados_redacao" on public.resultados_redacao
  for delete to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select, insert, delete on public.resultados_redacao to authenticated;

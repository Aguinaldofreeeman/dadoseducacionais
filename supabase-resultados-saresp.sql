-- Cria a estrutura usada pelo importador da SARESP em admin.html.
-- Execute uma vez no Supabase Dashboard > SQL Editor.
-- status: 'ouro' | 'diamante' | 'na' | 'sistema' (null na linha MARILIA/regional).

create table if not exists public.resultados_saresp (
  id uuid primary key default gen_random_uuid(),
  ano integer not null,
  escola text not null,
  nota numeric,
  status text,
  conquista_texto text,
  contato text,
  meta_ouro numeric,
  meta_diamante numeric,
  pp3bim numeric,
  created_at timestamptz default now(),
  unique (ano, escola)
);

alter table public.resultados_saresp enable row level security;

drop policy if exists "Select autenticado em resultados_saresp" on public.resultados_saresp;
create policy "Select autenticado em resultados_saresp" on public.resultados_saresp
  for select to authenticated using (true);

drop policy if exists "Insert autenticado em resultados_saresp" on public.resultados_saresp;
create policy "Insert autenticado em resultados_saresp" on public.resultados_saresp
  for insert to authenticated with check (true);

drop policy if exists "Delete apenas ADM em resultados_saresp" on public.resultados_saresp;
create policy "Delete apenas ADM em resultados_saresp" on public.resultados_saresp
  for delete to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
    )
  );

grant select, insert, delete on public.resultados_saresp to authenticated;

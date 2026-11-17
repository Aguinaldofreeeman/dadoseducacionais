-- ============================================================
-- supabase-contador-visitas.sql
-- Contador de visitas da index.html hospedado no Supabase.
--
-- A tabela fica protegida por RLS (sem politicas): o acesso
-- publico acontece apenas pelas funcoes SECURITY DEFINER:
--   - contador_visitas_registrar(p_chave): incrementa 1 e retorna o total
--     (chamado 1x por sessao do navegador, no primeiro load da index)
--   - contador_visitas_obter(p_chave): le o total sem incrementar
--
-- Base historica: 84 visitas (total do contador Abacus em 17/11/2026,
-- migado em 17/11/2026 antes da troca definitiva para o Supabase).
-- ============================================================

create table if not exists public.contador_visitas (
  chave text primary key,
  total bigint not null default 0,
  atualizado_em timestamptz not null default now()
);

alter table public.contador_visitas enable row level security;

-- Incrementa (1x por sessao do navegador) e retorna o novo total
create or replace function public.contador_visitas_registrar(p_chave text)
returns bigint
language plpgsql
security definer
set search_path = public
as $func$
declare v_total bigint;
begin
  insert into public.contador_visitas as c (chave, total)
  values (p_chave, 1)
  on conflict (chave) do update
    set total = c.total + 1, atualizado_em = now()
  returning total into v_total;
  return v_total;
end;
$func$;

-- Le o total sem incrementar
create or replace function public.contador_visitas_obter(p_chave text)
returns bigint
language sql
security definer
set search_path = public
as $func$
  select coalesce((select total from public.contador_visitas where chave = p_chave), 0);
$func$;

grant execute on function public.contador_visitas_registrar(text) to anon, authenticated;
grant execute on function public.contador_visitas_obter(text) to anon, authenticated;

-- Base historica (idempotente: nao sobrescreve se ja existir)
insert into public.contador_visitas (chave, total) values ('index', 84)
on conflict (chave) do nothing;

notify pgrst, 'reload schema';

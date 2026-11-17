-- ============================================================
-- Data e hora da última importação de cada módulo.
--
-- Exibida nos painéis como "Fonte: Escola Total. Atualizado em
-- dd/mm/aaaa hh:mm." e gravada automaticamente pelos importadores
-- do admin.html logo após a planilha ser enviada com sucesso.
--
-- Execute no SQL Editor do projeto Supabase configurado em config.js.
-- É idempotente: pode rodar mais de uma vez sem efeito colateral.
-- ============================================================

create table if not exists public.atualizacoes_dados (
  modulo text primary key,
  atualizado_em timestamptz not null default now(),
  atualizado_por uuid,
  periodo text,
  registros integer,
  detalhe jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

comment on table public.atualizacoes_dados is
  'Uma linha por módulo (tarefa, saresp, leia, ...). atualizado_em alimenta o rodapé "Atualizado em ..." dos painéis.';
comment on column public.atualizacoes_dados.periodo is
  'Recorte do último upload: semana, mês, quinzena, edição. Uso informativo.';

-- ------------------------------------------------------------
-- Leitura pública: os painéis leem a data mesmo sem login.
-- ------------------------------------------------------------
alter table public.atualizacoes_dados enable row level security;

drop policy if exists "Leitura pública das atualizações" on public.atualizacoes_dados;
create policy "Leitura pública das atualizações" on public.atualizacoes_dados
  for select to anon, authenticated using (true);

grant select on public.atualizacoes_dados to anon, authenticated;

-- Correção manual da data (ex.: importação feita fora do admin).
drop policy if exists "Escrita ADM em atualizações" on public.atualizacoes_dados;
create policy "Escrita ADM em atualizações" on public.atualizacoes_dados
  for update to authenticated using (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and upper(p.escopo) in ('ADM', 'ADMIN') and p.ativo = true
    )
  ) with check (
    exists (
      select 1 from public.perfis_usuarios p
      where p.id = auth.uid() and upper(p.escopo) in ('ADM', 'ADMIN') and p.ativo = true
    )
  );

grant update on public.atualizacoes_dados to authenticated;
revoke insert, delete on public.atualizacoes_dados from anon, authenticated;

-- ------------------------------------------------------------
-- Gravação automática pelos importadores.
-- SECURITY DEFINER: a data e o autor são carimbados no servidor,
-- então o navegador não consegue forjar "atualizado em".
-- ------------------------------------------------------------
-- Atualiza a RPC se a versão anterior (sem p_data) existir.
drop function if exists public.registrar_atualizacao(text, text, integer, jsonb);

create or replace function public.registrar_atualizacao(
  p_modulo text,
  p_periodo text default null,
  p_registros integer default null,
  p_detalhe jsonb default '{}'::jsonb,
  p_data timestamptz default null
) returns public.atualizacoes_dados
language plpgsql
security definer
set search_path = public
as $$
declare
  v_linha public.atualizacoes_dados;
begin
  if p_modulo is null or length(btrim(p_modulo)) = 0 then
    raise exception 'Informe o módulo da atualização.' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.perfis_usuarios p
    where p.id = auth.uid()
      and upper(p.escopo) in ('ADM', 'ADMIN')
      and p.ativo = true
  ) then
    raise exception 'Apenas usuários ADM podem registrar atualizações.' using errcode = '42501';
  end if;

  insert into public.atualizacoes_dados as a
    (modulo, atualizado_em, atualizado_por, periodo, registros, detalhe)
  values (
    btrim(p_modulo),
    coalesce(p_data, now()),
    auth.uid(),
    nullif(btrim(coalesce(p_periodo, '')), ''),
    p_registros,
    coalesce(p_detalhe, '{}'::jsonb)
  )
  on conflict (modulo) do update
    set atualizado_em  = coalesce(p_data, now()),
        atualizado_por = auth.uid(),
        periodo        = coalesce(excluded.periodo, a.periodo),
        registros      = excluded.registros,
        detalhe        = excluded.detalhe
  returning * into v_linha;

  return v_linha;
end;
$$;

revoke execute on function public.registrar_atualizacao(text, text, integer, jsonb, timestamptz) from anon;
grant execute on function public.registrar_atualizacao(text, text, integer, jsonb, timestamptz) to authenticated;

notify pgrst, 'reload schema';

-- ------------------------------------------------------------
-- Conferência rápida (opcional)
-- ------------------------------------------------------------
-- select modulo, atualizado_em, periodo, registros from public.atualizacoes_dados order by atualizado_em desc;

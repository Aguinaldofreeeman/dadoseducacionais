-- ============================================================
-- supabase-analytics.sql
-- Analytics de uso da plataforma — card de Analytics (exclusivo ADM)
-- na admin.html (abas). URE Marília.
-- Execute UMA VEZ no Supabase Dashboard > SQL Editor.
--
-- Segurança:
--   - a gravação passa pela RPC analytics_registrar (SECURITY DEFINER):
--     escopo e user_id são carimbados no servidor a partir do perfil
--     real, então o cliente não consegue forjar ADM;
--   - leitura e exclusão: somente ADM ativo (perfis_usuarios);
--   - anon não tem nenhuma privilégio de tabela — só executa a RPC.
--
-- Otimizações:
--   - analytics_resumo passou de stable para volatile (lê tabela mutável
--     e usa now());
--   - os 4 count(*) isolados viraram uma única passagem agregada;
--   - a série diária passou de 3 agregações para 1 (com filter);
--   - o objeto "eventos" foi removido (o front não o consome);
--   - "recentes" passou a projetar apenas as colunas usadas.
-- ============================================================

create extension if not exists pgcrypto;

-- 1) Tabela de eventos ---------------------------------------
create table if not exists public.analytics_eventos (
  id           uuid primary key default gen_random_uuid(),
  criado_em    timestamptz not null default now(),
  dia          date not null default ((now() at time zone 'America/Sao_Paulo')::date),
  evento       text not null,
  pagina       text not null default 'index.html',
  modulo       text,
  sessao_id    text,
  visitante_id text,
  user_id      uuid,
  escopo       text,
  referrer     text,
  user_agent   text,
  metadata     jsonb not null default '{}'::jsonb,
  constraint analytics_evento_tipo  check (evento in ('page_view','module_click','login','logout','heartbeat')),
  constraint analytics_pagina_len   check (char_length(pagina) between 1 and 200),
  constraint analytics_modulo_len   check (modulo is null or char_length(modulo) between 1 and 80)
);

create index if not exists analytics_eventos_dia_idx      on public.analytics_eventos (dia);
create index if not exists analytics_eventos_evento_idx   on public.analytics_eventos (evento);
create index if not exists analytics_eventos_modulo_idx   on public.analytics_eventos (modulo);
create index if not exists analytics_eventos_criado_idx   on public.analytics_eventos (criado_em desc);
create index if not exists analytics_eventos_dia_visit_idx on public.analytics_eventos (dia, visitante_id);

alter table public.analytics_eventos enable row level security;

-- 2) Helper: é ADM ativo? ------------------------------------
create or replace function public.is_adm()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from public.perfis_usuarios p
    where p.id = auth.uid()
      and p.ativo
      and upper(p.escopo) in ('ADM','ADMIN')
  );
$$;
revoke all on function public.is_adm() from public;
grant execute on function public.is_adm() to anon, authenticated;

-- 3) Policies -------------------------------------------------
drop policy if exists analytics_select_adm on public.analytics_eventos;
create policy analytics_select_adm on public.analytics_eventos
  for select to authenticated using (public.is_adm());

drop policy if exists analytics_delete_adm on public.analytics_eventos;
create policy analytics_delete_adm on public.analytics_eventos
  for delete to authenticated using (public.is_adm());

drop policy if exists analytics_insert_public on public.analytics_eventos;
drop policy if exists analytics_insert_adm on public.analytics_eventos;
create policy analytics_insert_adm on public.analytics_eventos
  for insert to authenticated with check (public.is_adm());

-- 4) RPC: registrar evento -----------------------------------
create or replace function public.analytics_registrar(
  evento text,
  pagina text default 'index.html',
  modulo text default null,
  sessao_id text default null,
  visitante_id text default null,
  referrer text default null,
  user_agent text default null,
  metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql volatile security definer set search_path = public
as $$
declare
  escopo_real text;
  meta jsonb;
begin
  if evento is null or evento not in ('page_view','module_click','login','logout','heartbeat') then
    raise exception 'evento_invalido';
  end if;

  meta := case when jsonb_typeof(metadata) = 'object' then metadata else '{}'::jsonb end;

  select p.escopo into escopo_real
  from public.perfis_usuarios p
  where p.id = auth.uid() and p.ativo;

  insert into public.analytics_eventos (
    evento, pagina, modulo, sessao_id, visitante_id,
    user_id, escopo, referrer, user_agent, metadata
  ) values (
    evento,
    left(coalesce(nullif(pagina, ''), 'index.html'), 200),
    left(modulo, 80),
    left(sessao_id, 120),
    left(visitante_id, 120),
    auth.uid(),
    escopo_real,
    left(referrer, 500),
    left(user_agent, 500),
    meta
  );
end;
$$;
revoke all on function public.analytics_registrar(text,text,text,text,text,text,text,jsonb) from public;
grant execute on function public.analytics_registrar(text,text,text,text,text,text,text,jsonb) to anon, authenticated;

-- 5) Grants explícitos (defesa em profundidade sobre os defaults)
revoke all on public.analytics_eventos from anon;
grant insert, select, delete on public.analytics_eventos to authenticated;

-- 6) RPC: resumo agregado (visão geral do card) --------------
create or replace function public.analytics_resumo(dias integer default 30)
returns jsonb
language plpgsql volatile security definer set search_path = public
as $$
declare
  inicio date;
  hoje   date := (now() at time zone 'America/Sao_Paulo')::date;
  resumo jsonb;
begin
  if not public.is_adm() then
    return jsonb_build_object('autorizado', false);
  end if;

  dias   := greatest(1, least(coalesce(dias, 30), 365));
  inicio := hoje - (dias - 1);

  -- totais: uma única passagem agregada
  with tot as (
    select
      count(*) filter (where evento = 'page_view')                        as visitas,
      count(*) filter (where evento = 'module_click')                     as cliques,
      count(*) filter (where evento = 'heartbeat')                        as heartbeats,
      count(distinct visitante_id) filter (where visitante_id is not null) as visitantes,
      count(distinct modulo) filter (where evento = 'module_click' and modulo is not null) as modulos_ativos,
      count(distinct pagina) filter (where pagina is not null) as paginas_acessadas
    from public.analytics_eventos
    where dia >= inicio
  )
  select jsonb_build_object(
    'autorizado', true,
    'dias', dias,
    'gerado_em', now(),
    'totais', jsonb_build_object(
      'visitas',        coalesce(t.visitas, 0),
      'cliques',        coalesce(t.cliques, 0),
      'visitantes',     coalesce(t.visitantes, 0),
      'modulos_ativos', coalesce(t.modulos_ativos, 0),
      'paginas_acessadas', coalesce(t.paginas_acessadas, 0)
    ),
    'serie', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'dia', d.dia,
        'visitas', coalesce(a.visitas, 0),
        'cliques', coalesce(a.cliques, 0),
        'visitantes', coalesce(a.visitantes, 0)
      ) order by d.dia), '[]'::jsonb)
      from (select generate_series(inicio, hoje, interval '1 day')::date as dia) d
      left join (
        select dia,
          count(*) filter (where evento = 'page_view')                        as visitas,
          count(*) filter (where evento = 'module_click')                     as cliques,
          count(distinct visitante_id) filter (where visitante_id is not null) as visitantes
        from public.analytics_eventos
        where dia >= inicio
        group by dia
      ) a on a.dia = d.dia
    ),
    'modulos', (
      select coalesce(jsonb_agg(jsonb_build_object('modulo', modulo, 'cliques', c) order by c desc), '[]'::jsonb)
      from (
        select modulo, count(*) c
        from public.analytics_eventos
        where evento = 'module_click' and dia >= inicio and modulo is not null
        group by modulo
      ) m
    ),
    'paginas', (
      select coalesce(jsonb_agg(jsonb_build_object('pagina', pagina, 'visitas', c) order by c desc), '[]'::jsonb)
      from (
        select pagina, count(*) c
        from public.analytics_eventos
        where pagina is not null and dia >= inicio
        group by pagina
      ) p
    ),
    'recentes', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'criado_em', criado_em, 'evento', evento, 'modulo', modulo, 'escopo', escopo, 'pagina', pagina
      ) order by criado_em desc), '[]'::jsonb)
      from (
        select criado_em, evento, modulo, escopo, pagina
        from public.analytics_eventos
        order by criado_em desc
        limit 10
      ) r
    )
  ) into resumo
  from tot t;

  return resumo;
end;
$$;
revoke all on function public.analytics_resumo(integer) from public;
grant execute on function public.analytics_resumo(integer) to anon, authenticated;

-- 7) RPC: detalhado por usuário (nome, email, tempo de uso, páginas) --
create or replace function public.analytics_usuarios(dias integer default 30)
returns jsonb
language plpgsql volatile security definer set search_path = public
as $$
declare
  inicio date;
  hoje   date := (now() at time zone 'America/Sao_Paulo')::date;
  resumo jsonb;
begin
  if not public.is_adm() then
    return jsonb_build_object('autorizado', false);
  end if;

  dias   := greatest(1, least(coalesce(dias, 30), 365));
  inicio := hoje - (dias - 1);

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', p.id,
    'nome', coalesce(p.nome, ''),
    'email', coalesce(p.email, ''),
    'funcao', coalesce(p.funcao, ''),
    'escopo', coalesce(p.escopo, ''),
    'ativo', p.ativo,
    'visitas', coalesce(u.visitas, 0),
    'cliques', coalesce(u.cliques, 0),
    'paginas_acessadas', coalesce(u.paginas_acessadas, 0),
    'tempo_uso_min', coalesce(u.tempo_uso_min, 0),
    'primeiro_acesso', u.primeiro_acesso,
    'ultimo_acesso', u.ultimo_acesso
  ) order by u.visitas desc, u.cliques desc), '[]'::jsonb)
  into resumo
  from (
    select
      e.user_id,
      count(*) filter (where e.evento = 'page_view')      as visitas,
      count(*) filter (where e.evento = 'module_click')   as cliques,
      count(distinct e.pagina)                            as paginas_acessadas,
      sum(coalesce(extra.dur_min, 0))                     as tempo_uso_min,
      min(e.criado_em)                                    as primeiro_acesso,
      max(e.criado_em)                                    as ultimo_acesso
    from public.analytics_eventos e
    left join lateral (
      -- duração em minutos estimada por sessão: delta entre primeiro e último evento
      -- do mesmo user_id no dia, com teto de 8h por sessão
      select
        least(
          extract(epoch from (max(criado_em) - min(criado_em)))/60.0,
          480.0
        ) as dur_min
      from public.analytics_eventos e2
      where e2.user_id = e.user_id
        and e2.dia = e.dia
        and e2.user_id is not null
    ) extra on true
    where e.user_id is not null
      and e.dia >= inicio
    group by e.user_id
  ) u
  right join public.perfis_usuarios p on p.id = u.user_id;

  -- Retorna envelope {autorizado, usuarios} para casar com o contrato
  -- esperado pelo cliente (admin.html), que lê data.usuarios.
  return jsonb_build_object('autorizado', true, 'usuarios', resumo);
end;
$$;
revoke all on function public.analytics_usuarios(integer) from public;
grant execute on function public.analytics_usuarios(integer) to anon, authenticated;

-- 8) RPC: purgar eventos antigos (manutenção ADM) ------------
create or replace function public.analytics_purgar(dias integer default 90)
returns integer
language plpgsql volatile security definer set search_path = public
as $$
declare
  apagados integer;
begin
  if not public.is_adm() then
    raise exception 'nao_autorizado';
  end if;
  delete from public.analytics_eventos
   where dia < ((now() at time zone 'America/Sao_Paulo')::date - greatest(1, coalesce(dias,90)));
  get diagnostics apagados = row_count;
  return apagados;
end;
$$;
revoke all on function public.analytics_purgar(integer) from public;
grant execute on function public.analytics_purgar(integer) to authenticated;

-- 9) Recarregar cache do PostgREST ---------------------------
notify pgrst, 'reload schema';

-- ============================================================================
--  PLATAFORMA DE DADOS EDUCACIONAIS - Manutenção do banco (Supabase SQL Editor)
--  Rode os blocos na ordem. Todos são idempotentes (podem rodar várias vezes).
--
--  STATUS (20/10/2026): Blocos 0, 1, 3 e 4 JÁ APLICADOS neste projeto.
--    - Visão vw_resultados_consolidados criada (520 linhas)
--    - Dedupe: dados_educacionais 5.720 -> 520 | resultados_alura 153 -> 51 (por ano)
--    - Políticas: DELETE e INSERT só para ADM
--    - Coluna total_alunos criada
--  Execute este arquivo novamente apenas se recriar o banco do zero.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BLOCO 0 (opcional): guardar o número de alunos por escola
-- A planilha oficial tem a coluna "Total Alunos". Sem esta coluna, o
-- importador ignora esse valor. Com ela, o dado passa a ser gravado.
-- ---------------------------------------------------------------------------
-- alter table public.dados_educacionais
--     add column if not exists total_alunos numeric;


-- ---------------------------------------------------------------------------
-- BLOCO 1 (opcional mas recomendado): visão consolidada dos resultados
-- Uma linha por (ano, edição, escola), com a linha mais completa da escola.
-- Evita o limite de 1000 linhas do PostgREST e deixa a página mais rápida.
-- ---------------------------------------------------------------------------create or replace view public.vw_resultados_consolidados
with (security_invoker = true)
as
with pontuadas as (
    select
        d.*,
        num_nonnulls(
            nullif(btrim(d.participacao::text), ''),
            nullif(btrim(d.acertos_prova::text), ''),
            nullif(btrim(d.evolucao::text), ''),
            nullif(btrim(d.port::text), ''),
            nullif(btrim(d.mat::text), ''),
            nullif(btrim(d.his::text), ''),
            nullif(btrim(d.geo::text), ''),
            nullif(btrim(d.bio::text), ''),
            nullif(btrim(d.qui::text), ''),
            nullif(btrim(d.ing::text), ''),
            nullif(btrim(d.cie::text), ''),
            nullif(btrim(d.fis::text), ''),
            nullif(btrim(d.ed_fin::text), ''),
            nullif(btrim(d.emp::text), ''),
            nullif(btrim(d.tec_rob::text), ''),
            nullif(btrim(d.ing_it::text), ''),
            nullif(btrim(d.art::text), ''),
            nullif(btrim(d.mid_dig::text), ''),
            nullif(btrim(d.lide::text), ''),
            nullif(btrim(d.oratoria::text), ''),
            nullif(btrim(d.geo_pol::text), ''),
            nullif(btrim(d.fil_e_soc_mod::text), ''),
            nullif(btrim(d.filo::text), ''),
            nullif(btrim(d.soc::text), ''),
            nullif(btrim(d.bio_tec::text), ''),
            nullif(btrim(d.quim_apl::text), '')
        ) as completude
    from public.dados_educacionais d
)
select distinct on (ano, edicao_planilha, escola)
    ano,
    edicao_planilha,
    escola,
    participacao,
    acertos_prova,
    evolucao,
    port, mat, his, geo, bio, qui, ing, cie, fis,
    ed_fin, emp, tec_rob, ing_it, art, mid_dig, lide,
    oratoria, geo_pol, fil_e_soc_mod, filo, soc, bio_tec, quim_apl
from pontuadas
order by ano, edicao_planilha, escola, completude desc, created_at desc;


-- ---------------------------------------------------------------------------
-- BLOCO 2: remover as importações duplicadas da Prova Paulista
-- Mantém a linha mais completa/mais recente de cada (ano, edição, escola).
-- ATENÇÃO: rode o BLOCO 3 antes deste, senão o DELETE é bloqueado pelo RLS.
-- Expectativa: 5.720 linhas -> 522 linhas
-- ---------------------------------------------------------------------------
-- delete from public.dados_educacionais d
-- where d.id not in (
--     select distinct on (ano, edicao_planilha, escola) id
--     from public.dados_educacionais
--     order by ano, edicao_planilha, escola, created_at desc
-- );


-- ---------------------------------------------------------------------------
-- BLOCO 3: permissões (RLS) para a plataforma poder limpar o ano na importação
-- DELETE só para ADM; INSERT/UPDATE/SELECT para qualquer usuário autenticado.
-- Rode este bloco ANTES dos blocos 2 e 4 (sem DELETE liberado, eles são ignorados).
-- ---------------------------------------------------------------------------
-- drop policy if exists "Delete apenas ADM em resultados_alura" on public.resultados_alura;
-- create policy "Delete apenas ADM em resultados_alura" on public.resultados_alura
--     for delete to authenticated
--     using (
--         exists (
--             select 1 from public.perfis_usuarios p
--             where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
--         )
--     );

-- drop policy if exists "Delete apenas ADM em dados_educacionais" on public.dados_educacionais;
-- create policy "Delete apenas ADM em dados_educacionais" on public.dados_educacionais
--     for delete to authenticated
--     using (
--         exists (
--             select 1 from public.perfis_usuarios p
--             where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
--         )
--     );


-- ---------------------------------------------------------------------------
-- BLOCO 4: remover as importações duplicadas da Alura
-- Expectativa: 153 linhas -> 51 linhas (50 escolas + linha Total)
-- ATENÇÃO: rode o BLOCO 3 antes deste, senão o DELETE é bloqueado pelo RLS.
-- ---------------------------------------------------------------------------
-- delete from public.resultados_alura r
-- where r.id not in (
--     select distinct on (escola, ano) id
--     from public.resultados_alura
--     order by escola, ano, created_at desc
-- );


-- ---------------------------------------------------------------------------
-- VERIFICAÇÃO
-- ---------------------------------------------------------------------------
-- select 'alura' as tabela, count(*) as linhas from public.resultados_alura
-- union all
-- select 'prova_paulista_bruta', count(*) from public.dados_educacionais
-- union all
-- select 'prova_paulista_visao', count(*) from public.vw_resultados_consolidados;

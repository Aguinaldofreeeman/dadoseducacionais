-- ============================================================================
-- ATUALIZADOR DA ALURA (re-sync)
-- Cria a tabela que o "Atualizador" do admin.html sincroniza via upsert.
-- Chave de re-sincronização: escola (apenas o nome da escola).
-- Ao reenviar a planilha, as escolas existentes são ATUALIZADAS e as novas
-- são INSERIDAS; as demais escolas permanecem no banco (não há DELETE total).
-- Rode no Supabase Dashboard -> SQL Editor. Idempotente.
-- ============================================================================

create table if not exists public.resultados_alura_resumo (
    id uuid primary key default gen_random_uuid(),
    ano integer not null,
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
    updated_at timestamptz default now(),
    unique (escola)
);

-- Gatilho para atualizar updated_at em conflitos de upsert
create or replace function public.trg_resultados_alura_resumo_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_resultados_alura_resumo_updated_at on public.resultados_alura_resumo;
create trigger trg_resultados_alura_resumo_updated_at
    before update on public.resultados_alura_resumo
    for each row execute function public.trg_resultados_alura_resumo_updated_at();

alter table public.resultados_alura_resumo enable row level security;

drop policy if exists "Select autenticado em resultados_alura_resumo" on public.resultados_alura_resumo;
create policy "Select autenticado em resultados_alura_resumo" on public.resultados_alura_resumo
    for select to authenticated
    using (true);

drop policy if exists "Insert autenticado em resultados_alura_resumo" on public.resultados_alura_resumo;
create policy "Insert autenticado em resultados_alura_resumo" on public.resultados_alura_resumo
    for insert to authenticated
    with check (true);

drop policy if exists "Update autenticado em resultados_alura_resumo" on public.resultados_alura_resumo;
create policy "Update autenticado em resultados_alura_resumo" on public.resultados_alura_resumo
    for update to authenticated
    using (true)
    with check (true);

drop policy if exists "Delete apenas ADM em resultados_alura_resumo" on public.resultados_alura_resumo;
create policy "Delete apenas ADM em resultados_alura_resumo" on public.resultados_alura_resumo
    for delete to authenticated
    using (
        exists (
            select 1 from public.perfis_usuarios p
            where p.id = auth.uid() and p.escopo in ('ADM', 'ADMIN')
        )
    );

grant select, insert, update, delete on public.resultados_alura_resumo to authenticated;

notify pgrst, 'reload schema';

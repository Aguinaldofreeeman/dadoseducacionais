-- ============================================================
-- Seed inicial: data base 17/11/2026 para todos os módulos.
--
-- Módulos que já tinham data conhecida (11/11 e 13/11) foram
-- mantidos com suas datas originais; os demais recebem a data
-- base, pois várias páginas exibiam apenas "Fonte: Escola Total."
-- sem data.
--
-- Idempotente: não sobrescreve registros que já existam
-- (importações reais feitas depois do deploy têm prioridade).
-- ============================================================

insert into public.atualizacoes_dados (modulo, atualizado_em, periodo, registros) values
  ('tarefa',           '2026-11-17 12:00:00-03', 'Semana 41',  null),
  ('alura',            '2026-11-17 12:00:00-03', '2026',       null),
  ('alura-mensal',     '2026-11-17 12:00:00-03', '2026-11',    null),
  ('presenca',         '2026-11-17 12:00:00-03', '2026',       null),
  ('matific-mensal',   '2026-11-17 12:00:00-03', '2026-11',    null),
  ('saresp',           '2026-11-17 12:00:00-03', '2026',       null),
  ('prova-paulista',   '2026-11-17 12:00:00-03', '2026',       null),
  ('leia',             '2026-11-17 12:00:00-03', 'Semana 1',   null),
  ('robotica',         '2026-11-17 12:00:00-03', '2026',       null),
  ('khan',             '2026-11-17 12:00:00-03', '2026-11',    null),
  ('matific',          '2026-11-17 12:00:00-03', '2026',       null),
  ('redacao',          '2026-11-17 12:00:00-03', '2026',       null),
  ('apoio',            '2026-11-17 12:00:00-03', '2026',       null),
  ('robotica-mensal',  '2026-11-17 12:00:00-03', '2026-11',    null)
on conflict (modulo) do nothing;

-- Confirmação
select modulo, atualizado_em, periodo from public.atualizacoes_dados order by atualizado_em desc;
```
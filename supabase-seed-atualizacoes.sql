-- ============================================================
-- Seed inicial: datas aproximadas dos últimos uploads conhecidos,
-- extraídas do código das páginas (antes do sistema automático).
--
-- Idempotente: não sobrescreve registros que já existam
-- (importações reais feitas depois do deploy têm prioridade).
-- Ajuste as datas/horas conforme necessário.
-- ============================================================

insert into public.atualizacoes_dados (modulo, atualizado_em, periodo, registros) values
  ('tarefa',           '2026-11-17 12:00:00-03', 'Semana 41',  null),
  ('alura',            '2026-11-17 12:00:00-03', '2026',       null),
  ('alura-mensal',     '2026-11-17 12:00:00-03', '2026-11',    null),
  ('presenca',         '2026-11-17 12:00:00-03', '2026',       null),
  ('matific-mensal',   '2026-11-17 12:00:00-03', '2026-11',    null),
  ('saresp',           '2026-11-11 12:00:00-03', '2026',       null),
  ('prova-paulista',   '2026-11-11 12:00:00-03', '2026',       null),
  ('leia',             '2026-11-11 12:00:00-03', 'Semana 1',   null),
  ('robotica',         '2026-11-11 12:00:00-03', '2026',       null),
  ('khan',             '2026-11-13 12:00:00-03', '2026-11',    null)
on conflict (modulo) do nothing;

-- Confirmação
select modulo, atualizado_em, periodo from public.atualizacoes_dados order by atualizado_em desc;
```<|end|><|start|>Assistant to=bash<|channel|>analysis <|constrain|>xml<|message|><rfl:parameter name="command">
cd "C:\Users\thiagoferreira\AppData\Local\Temp\opencode\dados-repo"; git add supabase-seed-atualizacoes.sql; git commit -m "Seed inicial das datas de importacao (11/11 e 17/11)"; $p="$env:USERPROFILE\.config\opencode\opencode.json"; $t=(Get-Content $p -Raw | ConvertFrom-Json).mcp.github.environment.GITHUB_PERSONAL_ACCESS_TOKEN; $b64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("x-access-token:$t")); git -c http.extraheader="AUTHORIZATION: basic $b64" push origin main 2>&1 | Select-String -Pattern "main ->|error|fatal"
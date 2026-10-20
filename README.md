# Plataforma de Dados Educacionais — URE Marília

Plataforma web (estática) para consulta e análise dos resultados da **Prova Paulista** e do
**engajamento na Plataforma Alura**, com autenticação Supabase e deploy automático
GitHub → Vercel.

**Produção:** https://dadoseducacionais.vercel.app

---

## 1. Arquitetura

```
GitHub (Aguinaldofreeeman/dadoseducacionais)
   │  push na branch main
   ▼
Vercel (projeto: dadoseducacionais)  ──►  site estático em dadoseducacionais.vercel.app
   ▲
   │  lê dados
Supabase (projeto: hygvdaixsqogcmcolnyx)
   ├─ Auth (login por e-mail/senha, perfis em perfis_usuarios)
   ├─ dados_educacionais   → resultados da Prova Paulista
   ├─ vw_resultados_consolidados (visão) → fonte do dashboard
   └─ resultados_alura     → engajamento na Plataforma Alura
```

- **Sem build**: HTML/CSS/JS puro. Bibliotecas via CDN (supabase-js, xlsx, Chart.js).
- **Deploy**: todo `git push` na `main` dispara o build na Vercel (testado e ativo).
- **Chave pública** (`sb_publishable_...`) no front-end é segura por design — a proteção real
  vem das políticas de RLS (ver seção 6).

## 2. Páginas

| Arquivo | Acesso | Função |
|---|---|---|
| `index.html` | público | Login e painel de módulos |
| `dashboard.html` | autenticado | **Seção 1: Prova Paulista** (KPIs, ranking, dispersão, disciplinas, evolução) e **Seção 2: Plataforma Alura** (KPIs, indicador principal por ano, engajamento, evolução) — analyzes **totalmente separadas** |
| `comparativo.html` | autenticado | **Análise cruzada** Alura × Prova Paulista (correlação, faixas de engajamento, leitura por escola) |
| `alura.html` | autenticado | Módulo Alura: tabela por escola/ano com filtro de ano letivo |
| `provapaulista.html` | autenticado | Porta de entrada do módulo Prova Paulista |
| `resultados_prova_paulista.html` | autenticado | Consulta por ano, bimestre e escola |
| `admin.html` | ADM | Usuários + **importadores** de planilha (Alura e Prova Paulista) |

Todas as páginas (exceto `index.html`) exigem sessão ativa e redirecionam para o login caso contrário.

## 3. Modelo de dados

### `dados_educacionais` — Prova Paulista (tabela bruta, 520 linhas)
| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid | |
| `ano` | text | 2024 / 2025 / 2026 |
| `edicao_planilha` | text | ex.: `Prova_Paulista_1º_bim_2026.xlsx` |
| `escola` | text | |
| `participacao` | text | razão 0–1 **ou** texto `"99,2%"` (formatos normalizados no front) |
| `acertos_prova` | text | idem |
| `evolucao` | text | |
| `port` `mat` `his` `geo` `bio` `qui` `ing` `cie` `fis` `ed_fin` `emp` `tec_rob` `ing_it` `art` `mid_dig` `lide` `oratoria` `geo_pol` `fil_e_soc_mod` `filo` `soc` `bio_tec` `quim_apl` | text | 24 colunas de disciplinas/indicadores |
| `total_alunos` | numeric | número de alunos da escola (opcional) |
| `created_at` | timestamptz | |

### `vw_resultados_consolidados` (visão sobre `dados_educacionais`)
Uma linha por **escola + ano + edição** (mantendo a linha mais completa). É a fonte do dashboard.
Colunas: as mesmas acima **sem** `id` e `created_at`.

### `resultados_alura` — Plataforma Alura (153 linhas: 3 anos × 51)
| Coluna | Tipo |
|---|---|
| `id` | uuid |
| `ano` | integer |
| `escola` | text |
| `matriculas_ativas` | numeric |
| `alunos_com_acessos_no_periodo` | numeric |
| `indice_de_acessos_no_periodo` | numeric |
| `cursos_concluidos` | numeric |
| `exercicios_realizados` | numeric |
| `projetos_enviados` | numeric |
| `indice_de_projetos_enviados` | numeric |
| `unidades_concluidas` | numeric |
| `total_de_exercicios_realizados` | numeric |
| `quantidade_media_de_tentativas_por_exercicio` | numeric |
| `total_de_acertos_ate_a_2_tentativa` | numeric |
| `indice_de_exercicios_corretos_ate_2a_tentativa` | numeric |
| `media_das_avaliacoes_mensais_entre_alunos_que_nao_zeraram` | numeric |
| `media_das_avaliacoes_mensais` | numeric |
| `indice_de_realizacao_das_avaliacoes_mensais` | numeric |
| `media_nas_questoes_discursivas` | numeric |
| `created_at` | timestamptz |

### `edicoes_disponiveis`
`ano` (text) · `edicao_planilha` (text) — catálogo das 9 edições (2024–2026).

### `perfis_usuarios`
`id` (uuid) · `nome` · `email` · `perfil` · `funcao` · `escopo` (text, `ADM`/`USER`) ·
`ativo` (boolean) · `criado_em` · `atualizado_em` · `created_at` (timestamptz)

## 4. Indicador principal por ano (Plataforma Alura)

Cada ano tem **um** indicador de avaliação — os demais nem existem na planilha oficial:

| Ano | Indicador principal | Campo | Observação |
|---|---|---|---|
| 2026 | Média das Avaliações Mensais | `media_das_avaliacoes_mensais` | nota média (ex.: 4,27) |
| 2025 | Índice de Exercícios Corretos até 2ª tentativa | `indice_de_exercicios_corretos_ate_2a_tentativa` | índice (ex.: 1,54) |
| 2024 | Índice de Projetos Enviados | `indice_de_projetos_enviados` | percentual (ex.: 20,0%) |

O dashboard destaca o indicador do ano selecionado em cards (média da rede, melhor e menor escola)
e em um gráfico Top 10. Essa configuração fica em `INDICADOR_PRINCIPAL` no `dashboard.html`
e no `comparativo.html`.

## 5. Importação de planilhas (Área Administrativa)

**Alura** — card "Importar Planilha Oficial - Alura":
1. Selecione o **Ano Letivo** e envie o `.xlsx`
2. **1. Ler e Pré-visualizar** → mostra nº de registros e colunas ignoradas
3. **2. Confirmar Importação** → apaga os dados do ano e grava os novos (idempotente)

**Prova Paulista** — card "Importar Planilha Oficial - Prova Paulista":
1. Selecione o **Ano Letivo** e envie o `.xlsx` (a edição é lida do nome do arquivo)
2. **1. Ler e Pré-visualizar** → mostra edição, nº de registros, **mapeamento das colunas** e amostra
3. **2. Confirmar Importação** → apaga os dados da edição e grava os novos

Regras implementadas:
- mapeamento automático de cabeçalhos (ex.: `Escolas`→`escola`, `HIST`→`his`, `FIN`→`ed_fin`, `TEC`→`bio_tec`)
- conversão de percentuais (`"98,4%"` → `0.984`)
- validação contra as colunas reais do banco (colunas divergentes são avisadas, não quebram a gravação)
- linhas de metadados (`FILTROS APLICADOS`, `CD_DIRETORIA`, `NM_DIRETORIA`) ignoradas
- limpeza do ano/edição antes de gravar (evita duplicatas)

## 6. Segurança (RLS)

Políticas ativas:

| Tabela | Leitura | Inserção | Exclusão |
|---|---|---|---|
| `dados_educacionais` | autenticados | **ADM** | **ADM** |
| `resultados_alura` | autenticados | **ADM** | **ADM** |
| `perfis_usuarios` | autenticados | autenticados | autenticados |

> A exclusão é liberada só para ADM porque o importador precisa limpar o ano antes de gravar.

Manutenção do banco: **`supabase-manutencao.sql`** (visão consolidada, dedupe, políticas, coluna opcional).
Os blocos de dedupe já foram aplicados em 20/10/2026 (5.720 → 520 linhas na Prova Paulista;
153 → 51 por ano na Alura). O script é idempotente e pode ser reaplicado.

## 7. Autenticação

- **Site URL**: `https://dadoseducacionais.vercel.app`
- **Redirect URLs**: `https://dadoseducacionais.vercel.app` e `https://dadoseducacionais.vercel.app/**`
- Troca de senha: Área Administrativa → editar usuário → reset por e-mail, **ou**
  Supabase Dashboard → Authentication → Users → editar a senha direto (mais rápido, sem e-mail).
- ⚠️ O serviço de e-mail padrão do Supabase tem **limite de 2 envios/hora**. Para uso intensively
  é necessário configurar um SMTP próprio em Authentication → Email.

## 8. As 3 análises mais úteis (Prova Paulista)

1. **Participação × Desempenho** — separa 4 grupos de escolas (participa e acerta / não participa /
   participa e não acerta / poucos dados) para definir onde agir primeiro.
2. **Evolução por escola e edição** — 9 edições (3 anos × 3 bimestres) mostram quem subiu, quem caiu
   e o efeito de cada bimestre na rede.
3. **Perfil de competências** — 24 colunas de disciplinas revelam onde a rede falha
   (hoje: Português ~57% × Matemática ~46%).

Bônus (página `comparativo.html`): cruzar o engajamento na Alura com o resultado da prova —
a correlação atual é 0,38 (moderada e positiva) e as escolas de alto engajamento têm
~3,9 p.p. a mais de acerto.

## 9. Desenvolvimento local

```bash
git clone https://github.com/Aguinaldofreeeman/dadoseducacionais
cd dadoseducacionais
# editar config.js com as credenciais (ou sobrescrever via variáveis de ambiente)
# servir em qualquer servidor estático, ex.:
npx serve .        # ou python -m http.server 8080
```

Deploy manual (quando o auto-deploy não desirable):

```bash
npx vercel --prod --yes
```

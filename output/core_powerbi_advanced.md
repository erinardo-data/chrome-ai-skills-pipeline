# core_powerbi_advanced.md
> **Skill consolidada a partir de 16 fontes especializadas** · skills.sh ecosystem  
> Fontes: github/awesome-copilot · microsoft/fabric-cli · microsoft/skills-for-fabric · data-goblin · datacoolie · josiahsiegel · membranedev  
> **Última compilação:** Maio/2026 · Versão: 2.0.0

---

## 📋 Índice

1. [Resumo Executivo da Skill](#resumo-executivo)
2. [Arquitetura de Dados — Star Schema](#arquitetura)
3. [Modelagem Semântica — Conceitos Fundamentais](#modelagem)
4. [DAX — Hierarquia e Otimização](#dax)
5. [Power Query (M) — Transformações e Folding](#power-query)
6. [Design de Relatórios](#design)
7. [Performance & Troubleshooting](#performance)
8. [Row-Level Security (RLS)](#rls)
9. [Fabric CLI & Automação](#fabric-cli)
10. [Pipeline de Análise de Negócio (Business Analysis)](#business-analysis)
11. [Melhores Práticas — Checklist Executivo](#checklist)
12. [Anti-Padrões a Evitar](#anti-padroes)

---

## 1. Resumo Executivo da Skill {#resumo-executivo}

Esta skill consolida o conhecimento de **nível sênior em Power BI** extraído de 16 fontes especializadas do ecossistema skills.sh, cobrindo o ciclo completo de desenvolvimento analítico:

| Domínio | Cobertura |
|---|---|
| **Modelagem Semântica** | Star schema, relacionamentos, tabela de datas, cardinalidade, bridge tables |
| **DAX** | Medidas, variáveis, contexto de filtro, time intelligence, iteradores, otimização |
| **Power Query (M)** | Transformações, query folding, funções customizadas, parâmetros, TMDL |
| **Design de Relatórios** | Seleção de visuais, layout, acessibilidade, mobile, temas PBIR |
| **Performance** | Diagnóstico sistemático, storage modes, otimização de consultas |
| **Segurança** | RLS estático, dinâmico e hierárquico |
| **Fabric CLI** | Automação via `fab` CLI, TMDL, PBIP/PBIX |
| **Governança** | Documentação, nomenclatura, audit, qualidade de modelo |

**Postura do agente:** Criar soluções analíticas **performáticas**, **documentadas** e de **fácil manutenção**, conectando-se ao modelo ativo antes de qualquer intervenção.

---

## 2. Arquitetura de Dados — Star Schema {#arquitetura}

### 2.1 Topologia Obrigatória

```
                    ┌─────────────┐
                    │  DimDate    │
                    │  (DateKey)  │
                    └──────┬──────┘
                           │ *:1
┌─────────────┐     ┌──────┴──────┐     ┌──────────────┐
│  DimProduct │─*:1─│  FactSales  │─1:*─│ DimCustomer  │
└─────────────┘     │             │     └──────────────┘
                    │  OrderID    │
┌─────────────┐     │  ProductKey │     ┌──────────────┐
│  DimStore   │─*:1─│  CustomerKey│     │FactInventory │
└─────────────┘     │  DateKey    │     └──────────────┘
                    │  StoreKey   │
                    └─────────────┘
```

### 2.2 Componentes do Modelo

| Componente | Função | Exemplos |
|---|---|---|
| **Fact Table** | Eventos/transações numéricas | Sales, Orders, WebVisits, Inventory |
| **Dimension Table** | Atributos descritivos | Date, Product, Customer, Geography |
| **Bridge Table** | Resolução many-to-many | StudentCourse, OrderProduct |

### 2.3 Tabelas Padrão

**Tabelas de Fato**
- `FactSales` — `OrderID, ProductKey, CustomerKey, DateKey, StoreKey, Quantity, Amount`
- `FactInventory` — `ProductKey, DateKey, StockLevel, ReorderPoint`

**Tabelas de Dimensão**
- `DimProduct` — `ProductKey, ProductName, Category, SubCategory, Price`
- `DimCustomer` — `CustomerKey, CustomerName, Segment, Region, Country`
- `DimDate` — `DateKey, Date, Year, Quarter, Month, MonthName, Week, Day, IsWeekend, FiscalYear`
- `DimStore` — `StoreKey, StoreName, Region, Manager`

### 2.4 Regras de Relacionamento

| Regra | Padrão | Observação |
|---|---|---|
| **Cardinalidade** | Many-to-One (`*:1`) | Padrão absoluto |
| **Direção de filtro** | Single | Usar `Both` apenas quando estritamente necessário |
| **Chaves** | Inteiras (Int64) | Nunca strings como chaves de relacionamento |
| **Relacionamentos inativos** | `USERELATIONSHIP()` | Ativar pontualmente dentro de medidas |
| **Many-to-Many** | Bridge Table | Evitar bidirecionais diretos |

---

## 3. Modelagem Semântica — Conceitos Fundamentais {#modelagem}

### 3.1 Tabela de Datas (obrigatória em produção)

- **Criar via DAX** com `CALENDAR()` + `ADDCOLUMNS()`
- **Marcar como Date Table** via `Table Tools → Mark as Date Table`
- Campos obrigatórios: `Year, Quarter, QuarterNum, Month, MonthNum, MonthYear, Week, Day, DayOfWeek, IsWeekend, FiscalYear, FiscalQuarter`
- **NUNCA** usar Auto Date/Time em produção

### 3.2 Connectivity Modes — Storage Strategy

| Modo | Quando usar | Trade-off |
|---|---|---|
| **Import** | Dados históricos, performance máxima | Requer refresh agendado |
| **DirectQuery** | Dados em tempo real, volumes enormes | Latência maior nas queries |
| **Dual** | Tabelas de dimensão compartilhadas | Flexibilidade com custo de complexidade |
| **Composite** | Mistura Import + DirectQuery | Configuração avançada |

### 3.3 Avaliação de Qualidade do Modelo

**Framework de Review em 3 Fases:**

**Fase 1 — Arquitetura do Schema**
- [ ] Star schema implementado (sem snowflake desnecessário)
- [ ] Grain consistency nas tabelas de fato
- [ ] Dimensões contendo apenas atributos descritivos
- [ ] Bridge tables para relacionamentos M:N
- [ ] Colunas técnicas/chaves ocultas do relatório

**Fase 2 — Performance e Escalabilidade**
- [ ] Storage modes otimizados por tabela
- [ ] Cardinalidade de colunas avaliada
- [ ] Relacionamentos em chaves inteiras
- [ ] Sem relacionamentos bidirecionais injustificados
- [ ] Tabela de datas criada manualmente e marcada

**Fase 3 — Manutenabilidade e Governança**
- [ ] Nomenclatura consistente (PascalCase para tabelas, nomes claros para medidas)
- [ ] Descrições adicionadas a tabelas, colunas e medidas
- [ ] Medidas organizadas em pastas (Display Folders)
- [ ] Documentação de todos os papéis RLS

### 3.4 Nomenclatura Padronizada

| Objeto | Padrão | Exemplo |
|---|---|---|
| Tabelas de Fato | `Fact` + PascalCase | `FactSales`, `FactInventory` |
| Tabelas de Dimensão | `Dim` + PascalCase | `DimCustomer`, `DimDate` |
| Medidas DAX | Verbos/Substantivos claros | `Total Sales`, `YoY Growth %` |
| Colunas calculadas | snake_case ou PascalCase | `IsWeekend`, `RevenueCategory` |
| Chaves primárias | `[Entidade]Key` | `ProductKey`, `CustomerKey` |

---

## 4. DAX — Hierarquia e Otimização {#dax}

### 4.1 Hierarquia de Funções por Importância

```
1. CALCULATE()       → Modifica contexto de filtro (a mais importante)
2. FILTER()          → Filtra tabela linha a linha
3. ALL / ALLSELECTED / ALLEXCEPT → Removem filtros
4. VAR / RETURN      → Variáveis para performance e legibilidade
5. Time Intelligence → TOTALYTD, SAMEPERIODLASTYEAR, DATEADD
6. Iterators (X)     → SUMX, AVERAGEX, RANKX, COUNTX
7. Table Functions   → SUMMARIZE, ADDCOLUMNS, TOPN, SELECTCOLUMNS
```

### 4.2 Contexto de Filtro vs. Contexto de Linha

| Tipo | Quando ocorre | Como usar |
|---|---|---|
| **Filter Context** | Slicers, visuais, CALCULATE | `CALCULATE([Medida], Filtro)` |
| **Row Context** | Colunas calculadas, iteradores X | Linha atual da tabela |
| **Transição de contexto** | Medida dentro de iterador | `CALCULATE()` converte row → filter |

### 4.3 Família ALL — Guia Completo

| Função | Comportamento | Uso típico |
|---|---|---|
| `ALL(Tabela)` | Remove todos os filtros da tabela | % do total |
| `ALL(Tabela[Coluna])` | Remove filtro apenas da coluna | Ranking |
| `ALLSELECTED()` | Remove filtros internos, mantém slicers externos | % do selecionado |
| `ALLEXCEPT(Tabela, Col1)` | Remove todos exceto as colunas listadas | Acumulados por grupo |
| `REMOVEFILTERS()` | Alternativa moderna ao ALL | Código mais legível |
| `KEEPFILTERS()` | Adiciona filtro sem remover os existentes | Filtros aditivos |

### 4.4 Framework de Otimização de Fórmulas DAX

**Análise em 4 Dimensões (power-bi-dax-optimization):**

1. **Performance** — Gargalos de cálculo, expressões repetidas, transições de contexto desnecessárias
2. **Legibilidade** — Clareza da fórmula, uso de variáveis, comentários
3. **Conformidade com Boas Práticas** — Uso correto de funções, DIVIDE vs. `/`
4. **Manutenabilidade** — Complexidade ciclomática, acoplamento com outras medidas

**Estratégia de Otimização Passo a Passo:**
1. Extrair expressões repetidas em `VAR`
2. Substituir funções lentas por equivalentes mais rápidas (`COUNTROWS` vs `COUNT`)
3. Preferir `CALCULATE` a iteradores quando possível
4. Filtrar em tabelas de dimensão, não de fato
5. Usar `DIVIDE()` para evitar erros de divisão por zero
6. Preservar `BLANK()` em vez de converter para zero desnecessariamente

### 4.5 Time Intelligence — Referência Rápida

| Medida | Função DAX |
|---|---|
| Acumulado do Ano (YTD) | `TOTALYTD([Total Sales], DimDate[Date])` |
| Acumulado do Trimestre | `TOTALQTD(...)` |
| Acumulado do Mês | `TOTALMTD(...)` |
| Mesmo período ano anterior | `SAMEPERIODLASTYEAR(DimDate[Date])` |
| Mês anterior | `DATEADD(DimDate[Date], -1, MONTH)` |
| Últimos 30 dias | `DATESINPERIOD(DimDate[Date], LASTDATE(...), -30, DAY)` |
| Crescimento YoY % | `DIVIDE([Total Sales] - [Sales PY], [Sales PY])` |
| Média Móvel 3 meses | `DATESINPERIOD(..., -3, MONTH) / 3` |

---

## 5. Power Query (M) — Transformações e Folding {#power-query}

### 5.1 Ordem Obrigatória de Etapas

```
1. Source          → Conectar à fonte de dados
2. Filter early    ← CRÍTICO para query folding
3. Remove columns  → Eliminar colunas não utilizadas
4. Rename columns  → Padronizar nomenclatura
5. Change types    → Tipos nativos explícitos
6. Replace nulls   → Tratar valores ausentes
7. Add columns     → Colunas calculadas
8. Remove dupes    → Deduplicação
9. Group/Merge     → Agregações e joins (somente se necessário)
```

### 5.2 Query Folding — Regra de Ouro

> **Query Folding** = a transformação é "empurrada" para o banco de dados como SQL nativo, evitando carregar toda a tabela na memória do Power BI.

**O que mantém o folding ativo:**
- `Table.SelectRows()` aplicado diretamente na fonte
- `Table.RemoveColumns()` e `Table.RenameColumns()`
- `Table.TransformColumnTypes()` com tipos nativos

**O que QUEBRA o folding:**
- `Table.Buffer()` desnecessário
- Listas dinâmicas calculadas em M
- Funções nativas do M após transformações "non-foldable"
- `Table.AddColumn()` com lógica complexa antes do filtro

**Como verificar:** Clique direito na etapa → `View Native Query` (se disponível, folding está ativo)

### 5.3 Estrutura de Partition Expression (Semantic Models)

```text
let
    Source = Sql.Database(#"SqlEndpoint", #"Database"),
    Data = Source{[Schema="dbo", Item="Orders"]}[Data],
    #"Removed Columns" = Table.RemoveColumns(Data, {"InternalId"}),
    #"Changed Type" = Table.TransformColumnTypes(
        #"Removed Columns", {{"Amount", Currency.Type}}
    )
in
    #"Changed Type"
```

### 5.4 TMDL — Tabular Model Definition Language

O **TMDL** é o formato moderno para definição de modelos semânticos em PBIP projects, substituindo o BIM (JSON monolítico):

- Arquivos `.tmdl` editáveis diretamente em texto
- Suporte a versionamento Git nativo
- Indentação estrita (sem tabs, apenas espaços)
- Campos obrigatórios: `formatString`, `summarizeBy` para colunas numéricas

---

## 6. Design de Relatórios {#design}

### 6.1 Framework de Consulta de Design

**Levantamento de Requisitos Inicial (power-bi-report-design-consultation):**

```
□ Qual problema de negócio o relatório resolve?
□ Quem é o público-alvo? (Executivos / Analistas / Operadores)
□ Quais decisões este relatório irá apoiar?
□ Quais são os KPIs prioritários?
□ Como o relatório será acessado? (Desktop / Mobile / Apresentação)
```

### 6.2 Metodologia de Seleção de Visuais

| Objetivo | Visual Recomendado | Visual a Evitar |
|---|---|---|
| Resumo executivo / KPI | **Card / KPI Visual** | Tabela com muitas linhas |
| Tendência temporal | **Line Chart** | Bar chart para séries temporais |
| Comparação entre categorias | **Bar / Column Chart** | Pie chart com > 5 categorias |
| Distribuição geográfica | **Map / Filled Map** | Tabela de países |
| Análise de causa-raiz | **Decomposition Tree** | Série de gráficos separados |
| Fatores de influência | **Key Influencers** | Correlação manual |
| Análise cruzada | **Matrix** com conditional formatting | Tabela plana |
| Composição / proporção | **Stacked Bar / Treemap** | Donut chart aninhado |

### 6.3 Padrões por Audiência

**Dashboard Executivo:**
- KPI cards proeminentes no topo
- Máximo 5–7 visuais por página
- Paleta de cores semântica (verde = positivo, vermelho = negativo)
- Drill-through para páginas de detalhe

**Relatório Analítico:**
- Filtros e slicers visíveis e contextualizados
- Tabelas com conditional formatting
- Bookmarks para alternar entre visões (ex: Vendas vs. Lucro)
- Tooltips customizados para contexto adicional

**Dashboard Operacional:**
- Atualização em tempo real (DirectQuery quando necessário)
- Alertas visuais para limites críticos
- Layout denso com informações de estado

### 6.4 Acessibilidade e Qualidade Visual

- **Contraste mínimo:** 4.5:1 (conformidade WCAG)
- **Paletas colorblind-friendly:** Evitar verde/vermelho puros sem ícone adicional
- **Tipografia:** Hierarquia clara (título > subtítulo > corpo > rótulo)
- **Mobile Layout:** Testar via `Phone Layout` no Power BI Desktop
- **Regra 3-30-300:** 3 segundos para o insight principal, 30s para compreensão do contexto, 300s para análise completa

### 6.5 Anti-"Power BI Slop"

> **"Power BI Slop"** = relatórios genéricos, mal formatados, que priorizam estética sobre clareza analítica.

- **Foque em responder perguntas específicas**, não em "parecer bonito"
- **Minimize carga cognitiva** — cada visual deve ter uma única mensagem clara
- **Trabalhe dentro das restrições do Power BI** em vez de contorná-las
- Pushback quando o usuário solicitar visuais que contradizem as diretrizes

---

## 7. Performance & Troubleshooting {#performance}

### 7.1 Framework de Diagnóstico Sistemático (power-bi-performance-troubleshooting)

**Classificação do Problema:**

```
□ Carregamento / refresh do modelo
□ Carregamento de página do relatório
□ Responsividade de interações visuais
□ Velocidade de execução de queries
□ Restrições de capacidade (Premium/Fabric)
□ Problemas de conectividade com fontes de dados
```

### 7.2 Quatro Áreas Diagnósticas

| Área | Ferramentas | Métricas-Alvo |
|---|---|---|
| **Modelo e DAX** | Performance Analyzer, DAX Studio | Query time < 1s |
| **Layout e Visuais** | Performance Analyzer (página) | Render < 3s |
| **Infraestrutura** | Capacity Metrics App | CPU < 80%, Mem < 90% |
| **Fonte de Dados** | Query Diagnostics, Gateway logs | Latência de rede |

### 7.3 Quick Wins (30 minutos)

- [ ] Ativar **query folding** nas etapas do Power Query
- [ ] Remover visuais desnecessários ou ineficientes
- [ ] Substituir colunas calculadas por medidas
- [ ] Desabilitar Auto Date/Time
- [ ] Ocultar colunas e tabelas não utilizadas no relatório
- [ ] Reduzir número de relacionamentos bidirecionais
- [ ] Verificar cardinalidade das colunas de join

### 7.4 Otimizações Estratégicas (2–4 horas)

- [ ] Revisar storage mode de cada tabela (Import vs. DirectQuery vs. Dual)
- [ ] Implementar aggregations para tabelas volumosas
- [ ] Refatorar medidas DAX complexas com VAR
- [ ] Avaliar uso de Calculation Groups para reduzir medidas
- [ ] Configurar refresh incremental para fatos históricos
- [ ] Revisar e consolidar queries redundantes no Power Query

---

## 8. Row-Level Security (RLS) {#rls}

### 8.1 Tipos de RLS

| Tipo | Mecanismo | Exemplo |
|---|---|---|
| **Estático** | Valor hardcoded no papel | `[Country] = "USA"` |
| **Dinâmico** | `USERPRINCIPALNAME()` vs. tabela de segurança | Email do usuário logado |
| **Por hierarquia** | `PATHCONTAINS()` | Estrutura de gestores |
| **Com exceção de admin** | Combinação de OR | Admin libera, demais filtram |

### 8.2 Fluxo de Implementação

1. Criar papel (role) em **Modeling → Manage Roles**
2. Definir expressão DAX de filtro na tabela correta
3. Testar com **"View as Role"**
4. Documentar todos os papéis e suas regras
5. **NUNCA** burlar o RLS dentro de medidas

### 8.3 Padrão de Segurança com Tabela de Segurança

```
SecurityTable: [Email] | [Region] | [AccessLevel]
↓
DimEmployee: [EmployeeID] | [ManagerID] | [Email] | [Path]
↓
FactSales → filtrado pela região do usuário logado
```

---

## 9. Fabric CLI & Automação {#fabric-cli}

### 9.1 Operações com `fab` CLI

| Operação | Categoria | Trigger |
|---|---|---|
| Semantic model (dataset) | get, export, refresh, update | Automação de refresh |
| Report management | export, clone, rebind | Migração entre workspaces |
| DAX queries | Execute against semantic models | Validação programática |
| Refresh schedules | Manage and troubleshoot | Monitoramento |
| Gateway & Data Sources | Configure connections | Infra como código |
| TMDL operations | Read/write model files | CI/CD de modelos |

### 9.2 Pré-requisitos Fabric CLI

- `fab` CLI instalado e autenticado
- Permissões de workspace adequadas
- Para operações TMDL: PBIP project structure no repositório

### 9.3 PBIP vs. PBIX

| Formato | Vantagem | Quando usar |
|---|---|---|
| **PBIX** | Arquivo único, fácil de compartilhar | Reports simples, uso individual |
| **PBIP** | Versionável, CI/CD, TMDL editável | Projetos de equipe, DevOps |

**Estrutura PBIP:**
```
MyReport.pbip
├── MyReport.SemanticModel/
│   ├── definition/
│   │   ├── model.tmdl
│   │   └── tables/
├── MyReport.Report/
│   ├── definition.pbir
│   └── pages/
└── .platform
```

---

## 10. Pipeline de Análise de Negócio {#business-analysis}

### 10.1 Fase 1 — Business Analysis (datacoolie)

```
Step 1 → Step 2 → Step 3 → Step 4
CONTEXT   DOMAIN    INFO-ARCH OUTPUT
(WHO/     (KPIs por  (plano    (Requirements
 WHAT/    indústria)  de páginas) Document +
 HOW)                           handoff JSON)
```

**Output do Step 4:** Requirements Document + JSON de handoff para a Fase 2 (Semantic Model).

### 10.2 Fase 2 — Semantic Model Builder

- Conecta ao modelo ativo (Desktop ou Fabric) antes de intervir
- Analisa estrutura atual antes de recomendar mudanças
- Usa MCP Tools para operações no modelo
- Consulta Microsoft Learn para guidance mais recente antes de decisões de design

### 10.3 Fase 3 — Report Design & Publish

- Usa `pbir` CLI como caminho preferencial
- Fallback para edição direta de JSON PBIR
- Validação com `jq empty` antes de publicar

---

## 11. Melhores Práticas — Checklist Executivo {#checklist}

### Modelagem
- [ ] Star schema implementado (sem snowflake desnecessário)
- [ ] Tabela de datas criada manualmente e marcada
- [ ] Relacionamentos em chaves inteiras
- [ ] Colunas técnicas/chaves ocultas do relatório
- [ ] Sem relacionamentos bidirecionais injustificados
- [ ] Storage modes otimizados por tabela

### DAX
- [ ] Usar `VAR / RETURN` em medidas com cálculos repetidos
- [ ] Preferir `CALCULATE` a iteradores quando possível
- [ ] Usar `COUNTROWS` no lugar de `COUNT`
- [ ] Medidas em vez de colunas calculadas para agregações
- [ ] Usar `SELECTEDVALUE` para colunas de valor único
- [ ] Filtrar em tabelas de **dimensão**, não de fato
- [ ] Usar `DIVIDE()` em vez de `/` para evitar erros
- [ ] Preservar `BLANK()` — não converter para zero sem necessidade

### Power Query
- [ ] Filtrar cedo (query folding ativo)
- [ ] Usar parâmetros para conexões reutilizáveis
- [ ] Desabilitar "Include in report refresh" em queries de referência
- [ ] Documentar funções customizadas com comentários
- [ ] Tipos nativos explícitos (`Int64.Type`, `type date`)
- [ ] Nunca usar `Table.Buffer` desnecessariamente

### Segurança
- [ ] RLS implementado e testado com "View as Role"
- [ ] Roles documentados com descrição de negócio
- [ ] Sem bypass de RLS em medidas DAX

### Governança
- [ ] Nomenclatura padronizada em todo o modelo
- [ ] Descrições adicionadas a tabelas, colunas e medidas
- [ ] Display Folders organizando medidas por tema
- [ ] Versioning via PBIP + Git

---

## 12. Anti-Padrões a Evitar {#anti-padroes}

| Anti-Padrão | Por quê é ruim | Solução Correta |
|---|---|---|
| **Coluna calculada para agregações** | Armazenada no modelo, consome RAM permanentemente | Medida com `SUMX` ou `CALCULATE` |
| **Relacionamento bidirecional em tudo** | Ambiguidade de filtros, loops, lentidão | `CROSSFILTER()` pontual dentro de medidas |
| **Não usar VAR** | Recalcula a mesma expressão múltiplas vezes | Sempre extrair cálculos repetidos em `VAR` |
| **Filtrar tarde no M** | Carrega toda a tabela antes de filtrar | Filtrar no primeiro passo (query folding) |
| **Medida sobre medida sem CALCULATE** | Contexto errado, resultado incorreto | Envolver em `CALCULATE()` |
| **`IFERROR` em tudo** | Esconde erros reais de dados | `DIVIDE()` e validação na origem |
| **Auto Date/Time em produção** | Cria tabelas ocultas duplicadas, consome memória | Tabela de datas manual e marcada |
| **Snowflake sem justificativa** | Complexidade desnecessária, joins extras | Star schema com dimensões desnormalizadas |
| **`Table.Buffer` desnecessário** | Quebra query folding, força carga em memória | Remover; usar apenas quando necessário |
| **Strings como chaves de relacionamento** | Performance ruim nas joins, cardinalidade alta | Chaves inteiras (`Int64.Type`) |
| **Visuais decorativos sem insight** | Carga cognitiva, "Power BI Slop" | Cada visual responde uma pergunta específica |
| **Bypass de RLS em medidas** | Vazamento de dados para usuários não autorizados | RLS implementado na camada de modelo |
| **Medidas sem documentação** | Impossível manutenção por outros devs | Descrições e Display Folders obrigatórios |

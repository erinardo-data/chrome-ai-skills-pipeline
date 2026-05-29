# exemplos_powerbi_pratico.md
> **Exemplos práticos compilados de 16 fontes especializadas** · skills.sh ecosystem  
> Fontes: github/awesome-copilot · microsoft/fabric-cli · data-goblin · datacoolie · josiahsiegel  
> **Última compilação:** Maio/2026 · Versão: 2.0.0

---

## 📋 Índice

1. [Modelagem — Tabela de Datas](#tabela-datas)
2. [DAX — Medidas Básicas e Essenciais](#dax-basico)
3. [DAX — CALCULATE e Família ALL](#dax-calculate)
4. [DAX — Time Intelligence](#dax-time)
5. [DAX — Iteradores e Tabelas Virtuais](#dax-iteradores)
6. [DAX — Variáveis e Lógica Complexa](#dax-variaveis)
7. [DAX — Otimização: Antes vs. Depois](#dax-otimizacao)
8. [Power Query (M) — Transformações Fundamentais](#m-basico)
9. [Power Query (M) — Avançado e Query Folding](#m-avancado)
10. [Power Query (M) — Parâmetros e Funções Customizadas](#m-params)
11. [RLS — Row-Level Security Completo](#rls)
12. [TMDL — Semantic Model Definition](#tmdl)
13. [Fabric CLI — Automação via `fab`](#fabric-cli)
14. [Diagnóstico de Performance — Checklists](#performance-check)
15. [Design de Relatório — Framework de Consulta](#design-framework)

---

## 1. Modelagem — Tabela de Datas {#tabela-datas}

```dax
DimDate =
ADDCOLUMNS(
    CALENDAR(DATE(2020, 1, 1), DATE(2027, 12, 31)),
    "Year",           YEAR([Date]),
    "Quarter",        "Q" & FORMAT([Date], "Q"),
    "QuarterNum",     QUARTER([Date]),
    "Month",          FORMAT([Date], "MMMM"),
    "MonthNum",       MONTH([Date]),
    "MonthYear",      FORMAT([Date], "MMM YYYY"),
    "Week",           WEEKNUM([Date]),
    "Day",            DAY([Date]),
    "DayOfWeek",      FORMAT([Date], "dddd"),
    "DayOfWeekNum",   WEEKDAY([Date]),
    "IsWeekend",      WEEKDAY([Date]) IN {1, 7},
    "FiscalYear",     IF(MONTH([Date]) <= 6, YEAR([Date]), YEAR([Date]) + 1),
    "FiscalQuarter",  IF(MONTH([Date]) <= 6, QUARTER([Date]) + 2, QUARTER([Date]) - 2)
)
```

> ✅ **Depois de criar:** `Table Tools → Mark as Date Table → coluna [Date]`  
> ❌ **NUNCA** usar Auto Date/Time em produção.

---

## 2. DAX — Medidas Básicas e Essenciais {#dax-basico}

```dax
-- ─── Medidas fundamentais ───────────────────────────────────────
Total Sales        = SUM(FactSales[Amount])
Total Quantity     = SUM(FactSales[Quantity])
Average Sale       = AVERAGE(FactSales[Amount])
Distinct Customers = DISTINCTCOUNT(FactSales[CustomerKey])
Total Orders       = COUNTROWS(FactSales)           -- preferir a COUNT()

-- ─── Soma condicional — duas formas equivalentes ─────────────────

-- Com SUMX + FILTER (explícito)
Sales Above 100 =
SUMX(
    FILTER(FactSales, FactSales[Amount] > 100),
    FactSales[Amount]
)

-- Com CALCULATE (preferível — mais performático)
Sales Above 100 =
CALCULATE(
    [Total Sales],
    FactSales[Amount] > 100
)
```

---

## 3. DAX — CALCULATE e Família ALL {#dax-calculate}

### Filtros Básicos

```dax
-- Filtro simples
Sales USA =
CALCULATE([Total Sales], DimCustomer[Country] = "USA")

-- Múltiplos filtros (AND implícito)
Sales USA Electronics =
CALCULATE(
    [Total Sales],
    DimCustomer[Country] = "USA",
    DimProduct[Category] = "Electronics"
)

-- Lógica IN (equivale a OR)
Sales North America =
CALCULATE(
    [Total Sales],
    DimCustomer[Country] IN {"USA", "Canada", "Mexico"}
)
```

### Removendo Filtros — Família ALL

```dax
-- Remove filtro de uma coluna específica
Total Sales All Countries =
CALCULATE(
    [Total Sales],
    ALL(DimCustomer[Country])
)

-- ALLSELECTED: ignora filtros internos, mantém slicers externos
Sales % of Selected =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLSELECTED())
)

-- REMOVEFILTERS: alternativa moderna ao ALL (mais legível)
Sales All Products =
CALCULATE(
    [Total Sales],
    REMOVEFILTERS(DimProduct)
)

-- ALLEXCEPT: remove todos os filtros exceto os informados
Sales by Customer Total =
CALCULATE(
    [Total Sales],
    ALLEXCEPT(FactSales, FactSales[CustomerKey])
)
```

### Modificadores Avançados

```dax
-- KEEPFILTERS: adiciona filtro sem remover os existentes
Sales With Filter =
CALCULATE(
    [Total Sales],
    KEEPFILTERS(DimProduct[Category] = "Electronics")
)

-- USERELATIONSHIP: ativa relacionamento inativo
Sales by Ship Date =
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(FactSales[ShipDateKey], DimDate[DateKey])
)

-- CROSSFILTER: muda direção do relacionamento pontualmente
-- (preferível a bidirecional permanente no modelo)
Sales Both Ways =
CALCULATE(
    [Total Sales],
    CROSSFILTER(FactSales[ProductKey], DimProduct[ProductKey], BOTH)
)
```

---

## 4. DAX — Time Intelligence {#dax-time}

```dax
-- ─── Acumulados de período ────────────────────────────────────────
YTD Sales = TOTALYTD([Total Sales], DimDate[Date])
QTD Sales = TOTALQTD([Total Sales], DimDate[Date])
MTD Sales = TOTALMTD([Total Sales], DimDate[Date])

-- ─── Períodos anteriores ─────────────────────────────────────────
Sales PY             = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(DimDate[Date]))
Sales PM             = CALCULATE([Total Sales], DATEADD(DimDate[Date], -1, MONTH))
Sales Previous Qtr   = CALCULATE([Total Sales], PARALLELPERIOD(DimDate[Date], -1, QUARTER))

-- ─── Crescimento Year-over-Year ──────────────────────────────────
YoY Growth =
VAR CurrentYearSales  = [Total Sales]
VAR PreviousYearSales = [Sales PY]
RETURN
    DIVIDE(CurrentYearSales - PreviousYearSales, PreviousYearSales)

-- ─── Crescimento Month-over-Month ────────────────────────────────
MoM Growth = DIVIDE([Total Sales] - [Sales PM], [Sales PM])

-- ─── Últimos 30 dias ─────────────────────────────────────────────
Sales Last 30 Days =
CALCULATE(
    [Total Sales],
    DATESINPERIOD(DimDate[Date], LASTDATE(DimDate[Date]), -30, DAY)
)

-- ─── Média móvel de 3 meses ──────────────────────────────────────
Sales MA 3 Months =
CALCULATE(
    [Total Sales],
    DATESINPERIOD(DimDate[Date], LASTDATE(DimDate[Date]), -3, MONTH)
) / 3
```

---

## 5. DAX — Iteradores e Tabelas Virtuais {#dax-iteradores}

### Iteradores X

```dax
-- SUMX: cálculo linha a linha (receita = qty × preço)
Total Revenue =
SUMX(
    FactSales,
    FactSales[Quantity] * FactSales[UnitPrice]
)

-- AVERAGEX: média por entidade (valor médio por pedido)
Average Order Value =
AVERAGEX(
    VALUES(FactSales[OrderID]),
    [Total Sales]
)

-- COUNTX com condição
Orders Above 1000 =
COUNTX(
    FILTER(FactSales, [Total Sales] > 1000),
    FactSales[OrderID]
)

-- RANKX: ranking de produtos por vendas
Product Rank =
RANKX(
    ALL(DimProduct[ProductName]),
    [Total Sales],
    ,
    DESC,
    DENSE
)

-- Média ponderada
Weighted Average =
DIVIDE(
    SUMX(DimProduct, DimProduct[Price] * DimProduct[Weight]),
    SUM(DimProduct[Weight])
)
```

### Tabelas Virtuais

```dax
-- SUMMARIZE: tabela virtual agrupada
Sales by Category =
SUMX(
    SUMMARIZE(FactSales, DimProduct[Category], "CategorySales", [Total Sales]),
    [CategorySales]
)

-- Top 10 clientes com ADDCOLUMNS + TOPN
Top Customers =
TOPN(
    10,
    ADDCOLUMNS(
        VALUES(DimCustomer[CustomerName]),
        "CustomerSales", [Total Sales]
    ),
    [CustomerSales],
    DESC
)

-- SELECTCOLUMNS: projeção específica de colunas
Customer List =
SELECTCOLUMNS(
    DimCustomer,
    "Name",    DimCustomer[CustomerName],
    "Country", DimCustomer[Country]
)
```

---

## 6. DAX — Variáveis e Lógica Complexa {#dax-variaveis}

### VAR/RETURN — Padrões Essenciais

```dax
-- Variância vs. meta com proteção de BLANK
Sales vs Target =
VAR ActualSales  = [Total Sales]
VAR TargetSales  = [Sales Target]
VAR Variance     = ActualSales - TargetSales
VAR VariancePct  = DIVIDE(Variance, TargetSales)
RETURN
    IF(ISBLANK(TargetSales), BLANK(), VariancePct)

-- Customer Lifetime Value
Customer Lifetime Value =
VAR FirstPurchase =
    CALCULATE(MIN(FactSales[Date]), ALLEXCEPT(FactSales, FactSales[CustomerKey]))
VAR LastPurchase =
    CALCULATE(MAX(FactSales[Date]), ALLEXCEPT(FactSales, FactSales[CustomerKey]))
VAR DaysBetween  = DATEDIFF(FirstPurchase, LastPurchase, DAY)
VAR TotalSpend   =
    CALCULATE([Total Sales], ALLEXCEPT(FactSales, FactSales[CustomerKey]))
RETURN
    DIVIDE(TotalSpend, DIVIDE(DaysBetween, 365), 0)
```

### SWITCH — Seletor de Métrica e Tiers

```dax
-- Seletor de métrica (Field Parameter)
Metric Selector =
SWITCH(
    SELECTEDVALUE(MetricParameter[Metric]),
    "Revenue",  [Total Sales],
    "Profit",   [Total Profit],
    "Quantity", [Total Quantity],
    "Orders",   [Total Orders],
    BLANK()
)

-- Tier de cliente por LTV
Customer Tier =
VAR LTV = [Customer Lifetime Value]
RETURN
    SWITCH(
        TRUE(),
        LTV >= 10000, "VIP",
        LTV >= 5000,  "Gold",
        LTV >= 1000,  "Silver",
        "Bronze"
    )

-- Performance vs. meta com múltiplas condições
Sales Performance =
VAR CurrentSales = [Total Sales]
VAR TargetSales  = [Sales Target]
VAR GrowthRate   = [YoY Growth]
RETURN
    SWITCH(
        TRUE(),
        ISBLANK(CurrentSales),                            "No Data",
        CurrentSales >= TargetSales && GrowthRate >= 0.1, "Exceeding",
        CurrentSales >= TargetSales,                      "Meeting Target",
        CurrentSales >= TargetSales * 0.9,                "Close to Target",
        "Below Target"
    )
```

---

## 7. DAX — Otimização: Antes vs. Depois {#dax-otimizacao}

### Coluna Calculada vs. Medida

```dax
-- ❌ ERRADO: coluna calculada armazenada no modelo (consome RAM permanente)
TotalRevenue = FactSales[Quantity] * FactSales[UnitPrice]

-- ✅ CORRETO: medida calculada sob demanda
Total Revenue = SUMX(FactSales, FactSales[Quantity] * FactSales[UnitPrice])
```

### Expressões Repetidas vs. VAR

```dax
-- ❌ ERRADO: [Total Sales] calculado duas vezes
Margin % = ([Total Sales] - [Total Cost]) / [Total Sales]

-- ✅ CORRETO: cada expressão calculada uma única vez
Margin % =
VAR Sales  = [Total Sales]
VAR Cost   = [Total Cost]
VAR Margin = Sales - Cost
RETURN DIVIDE(Margin, Sales)
```

### Bidirecional vs. CROSSFILTER Pontual

```dax
-- ❌ EVITAR: relacionamento bidirecional permanente no modelo
--    (causa ambiguidade, loops e lentidão em toda query)

-- ✅ CORRETO: bidirecional apenas dentro da medida que precisa
Sales Both Ways =
CALCULATE(
    [Total Sales],
    CROSSFILTER(FactSales[ProductKey], DimProduct[ProductKey], BOTH)
)
```

### IFERROR vs. DIVIDE

```dax
-- ❌ ERRADO: oculta erros reais de dados
Safe Ratio = IFERROR([Sales] / [Target], 0)

-- ✅ CORRETO: tratamento explícito e transparente
Safe Ratio = DIVIDE([Sales], [Target], 0)
```

---

## 8. Power Query (M) — Transformações Fundamentais {#m-basico}

```m
let
    Source = Sql.Database("server", "database"),
    FactSales = Source{[Schema="dbo", Item="FactSales"]}[Data],

    // 1. Filtrar CEDO — mantém query folding ativo
    FilteredRows = Table.SelectRows(FactSales,
        each [OrderDate] >= #date(2020, 1, 1)),

    // 2. Remover colunas desnecessárias
    RemovedColumns = Table.RemoveColumns(FilteredRows,
        {"UnneededColumn1", "UnneededColumn2"}),

    // 3. Renomear colunas
    RenamedColumns = Table.RenameColumns(RemovedColumns, {
        {"old_name",   "NewName"},
        {"order_date", "OrderDate"}
    }),

    // 4. Alterar tipos de dados com tipos nativos
    ChangedTypes = Table.TransformColumnTypes(RenamedColumns, {
        {"OrderDate", type date},
        {"Amount",    type number},
        {"Quantity",  Int64.Type}
    }),

    // 5. Adicionar coluna calculada
    AddedCustom = Table.AddColumn(ChangedTypes, "Revenue",
        each [Quantity] * [UnitPrice], type number),

    // 6. Substituir valores nulos
    ReplacedValues = Table.ReplaceValue(AddedCustom, null, 0,
        Replacer.ReplaceValue, {"Discount"}),

    // 7. Remover duplicatas pela chave primária
    RemovedDuplicates = Table.Distinct(ReplacedValues, {"OrderID"})

in
    RemovedDuplicates
```

### Tratamento de Erros em CSV

```m
let
    Source = Csv.Document(File.Contents("C:\data\sales.csv"),
        [Delimiter=",", Columns=5, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    // Tratar erros de conversão na coluna Amount
    CleanedAmount = Table.TransformColumns(PromotedHeaders, {
        {"Amount", each try Number.From(_) otherwise 0, type number}
    }),

    // Remover linhas com erros em colunas críticas
    RemovedErrors = Table.RemoveRowsWithErrors(CleanedAmount, {"OrderDate"})
in
    RemovedErrors
```

---

## 9. Power Query (M) — Avançado e Query Folding {#m-avancado}

### Query Folding — Certo vs. Errado

```m
// ❌ ERRADO: carrega TODA a tabela antes de filtrar
let
    Source       = Sql.Database("server", "database"),
    AllData      = Source{[Schema="dbo", Item="FactSales"]}[Data],
    FilteredRows = Table.SelectRows(AllData, each [Year] = 2024)
    // ↑ Folding pode quebrar dependendo das transformações anteriores
in
    FilteredRows

// ✅ CORRETO: filtro empurrado para o banco como SQL nativo
let
    Source       = Sql.Database("server", "database"),
    FilteredData = Table.SelectRows(
        Source{[Schema="dbo", Item="FactSales"]}[Data],
        each [Year] = 2024
    )
    // ↑ SQL gerado: SELECT * FROM dbo.FactSales WHERE Year = 2024
in
    FilteredData
```

### Transformações Avançadas

```m
let
    Source    = Sql.Database("server", "database"),
    FactSales = Source{[Schema="dbo", Item="FactSales"]}[Data],
    DimProduct = Source{[Schema="dbo", Item="DimProduct"]}[Data],

    // Coluna condicional
    AddedConditional = Table.AddColumn(FactSales, "Segment",
        each if [Amount] >= 1000 then "High"
             else if [Amount] >= 500  then "Medium"
             else "Low",
        type text),

    // Agrupar por cliente
    GroupedRows = Table.Group(FactSales, {"CustomerID"}, {
        {"TotalSales",  each List.Sum([Amount]),     type number},
        {"OrderCount",  each Table.RowCount(_),      Int64.Type},
        {"AvgAmount",   each List.Average([Amount]), type number}
    }),

    // Left Join com DimProduct
    Merged = Table.NestedJoin(
        FactSales, {"ProductKey"},
        DimProduct, {"ProductKey"},
        "Product",
        JoinKind.LeftOuter
    ),
    Expanded = Table.ExpandTableColumn(Merged, "Product",
        {"ProductName", "Category"},
        {"ProductName", "Category"}),

    // Append (UNION) de tabelas de anos diferentes
    Sales2023 = Source{[Schema="dbo", Item="Sales2023"]}[Data],
    Sales2024 = Source{[Schema="dbo", Item="Sales2024"]}[Data],
    Appended  = Table.Combine({Sales2023, Sales2024}),

    // Pivot: valores de coluna → novas colunas
    Pivoted = Table.Pivot(
        FactSales,
        List.Distinct(FactSales[Category]),
        "Category", "Amount", List.Sum
    ),

    // Unpivot: colunas → linhas
    Unpivoted = Table.UnpivotOtherColumns(FactSales,
        {"Date", "Product"}, "Attribute", "Value")

in
    Expanded
```

---

## 10. Power Query (M) — Parâmetros e Funções Customizadas {#m-params}

### Parâmetros de Ambiente e Data

```m
// Parâmetro de ambiente (criado via Manage Parameters)
EnvironmentParameter = "Production"
    meta [IsParameterQuery = true, Type = "Text",
          AllowedValues = {"Development", "Production"}]

// Parâmetros de data
StartDate = #date(2024, 1, 1)
    meta [IsParameterQuery = true, Type = "Date"]

EndDate = #date(2024, 12, 31)
    meta [IsParameterQuery = true, Type = "Date"]

// Conexão dinâmica baseada em parâmetro
let
    Server = if EnvironmentParameter = "Production"
             then "prod-server.database.windows.net"
             else "dev-server.database.windows.net",
    Source       = Sql.Database(Server, "SalesDB"),
    FactSales    = Source{[Schema="dbo", Item="FactSales"]}[Data],
    FilteredRows = Table.SelectRows(FactSales,
        each [OrderDate] >= StartDate and [OrderDate] <= EndDate)
in
    FilteredRows
```

### Função Customizada com Parâmetros de Data

```m
// Definição da função reutilizável
let
    GetSalesByDate = (startDate as date, endDate as date) as table =>
    let
        Source       = Sql.Database("server", "database"),
        FactSales    = Source{[Schema="dbo", Item="FactSales"]}[Data],
        FilteredRows = Table.SelectRows(FactSales,
            each [OrderDate] >= startDate and [OrderDate] <= endDate)
    in
        FilteredRows
in
    GetSalesByDate

// Invocação
// Sales2024 = GetSalesByDate(#date(2024, 1, 1), #date(2024, 12, 31))
```

### Partition Expression para Semantic Models (PBIP)

```m
// Estrutura padrão de partition em modelo semântico
let
    Source = Sql.Database(#"SqlEndpoint", #"Database"),
    Data   = Source{[Schema="dbo", Item="Orders"]}[Data],
    #"Removed Columns" = Table.RemoveColumns(Data, {"InternalId", "TempFlag"}),
    #"Changed Type" = Table.TransformColumnTypes(
        #"Removed Columns",
        {{"Amount", Currency.Type}, {"OrderDate", type date}}
    )
in
    #"Changed Type"
```

---

## 11. RLS — Row-Level Security Completo {#rls}

> As expressões abaixo são inseridas em: `Modeling → Manage Roles → [tabela]`

### RLS Estático

```dax
-- Papel: Sales_USA
[Country] = "USA"

-- Papel: North_and_South (múltiplas regiões)
[Region] = "North" || [Region] = "South"
```

### RLS Dinâmico com USERPRINCIPALNAME()

```dax
-- Papel: Regional_Manager (filtra pela coluna = e-mail do usuário logado)
[Region] = USERPRINCIPALNAME()

-- Com tabela de segurança (SecurityTable: Email | Region)
[Region] IN
    CALCULATETABLE(
        VALUES(SecurityTable[Region]),
        SecurityTable[Email] = USERPRINCIPALNAME()
    )
```

### RLS por Hierarquia de Gestores

```dax
-- EmployeeTable: EmployeeID | ManagerID | Email | Path
-- Path = hierarquia codificada ex: "1|5|12|47"
VAR CurrentUser =
    USERPRINCIPALNAME()
VAR CurrentEmployeeID =
    LOOKUPVALUE(
        EmployeeTable[EmployeeID],
        EmployeeTable[Email], CurrentUser
    )
RETURN
    PATHCONTAINS(EmployeeTable[Path], CurrentEmployeeID)
```

### RLS com Exceção de Admin

```dax
-- Libera acesso total para admin, aplica filtro regional para demais
[Region] = "North" ||
USERPRINCIPALNAME() = "admin@company.com"
```

---

## 12. TMDL — Semantic Model Definition {#tmdl}

### Estrutura de Medida em TMDL

```yaml
/// Total Sales measure
measure 'Total Sales' = SUM(FactSales[Amount])
    formatString: \#,##0.00
    displayFolder: Sales Metrics
    description: "Sum of all sales amounts across all fact records."
```

### Coluna com Tipos Explícitos

```yaml
column Amount
    dataType: decimal
    summarizeBy: sum
    formatString: \#,##0.00
    description: "Transaction amount in local currency."
```

### Relacionamento em TMDL

```yaml
relationship FactSales_DimProduct
    fromTable: FactSales
    fromColumn: ProductKey
    toTable: DimProduct
    toColumn: ProductKey
    isActive: true
    crossFilteringBehavior: singleDirection
```

---

## 13. Fabric CLI — Automação via `fab` {#fabric-cli}

### Operações Básicas com Semantic Model

```bash
# Listar todos os workspaces
fab workspace list

# Encontrar workspace pelo nome com JMESPath
fab workspace list --query "[?displayName=='MyWorkspace']"

# Listar itens de um workspace
fab item list --workspace-id <workspace-id> --type SemanticModel

# Exportar modelo semântico (PBIP/TMDL)
fab item export \
  --workspace-id <workspace-id> \
  --item-id <item-id> \
  --output-dir ./model-export

# Atualizar (refresh) modelo semântico
fab item refresh \
  --workspace-id <workspace-id> \
  --item-id <item-id>

# Executar query DAX contra o modelo
fab dax execute \
  --workspace-id <workspace-id> \
  --item-id <item-id> \
  --query "EVALUATE TOPN(10, DimProduct, [ProductKey])"
```

### Gerenciamento de Reports

```bash
# Exportar relatório como PBIX
fab item export \
  --workspace-id <workspace-id> \
  --item-id <report-id> \
  --format PBIX \
  --output-dir ./reports

# Rebind: associar relatório a novo modelo semântico
fab report rebind \
  --workspace-id <workspace-id> \
  --report-id <report-id> \
  --dataset-id <new-model-id>

# Clonar relatório para outro workspace
fab item clone \
  --workspace-id <source-workspace-id> \
  --item-id <report-id> \
  --target-workspace-id <target-workspace-id>
```

---

## 14. Diagnóstico de Performance — Checklists {#performance-check}

### Quick Wins (≈ 30 minutos)

```text
MODELO
□ Desabilitar Auto Date/Time (File → Options → Current File → Data Load)
□ Verificar query folding ativo em todas as queries M
□ Remover colunas e tabelas não utilizadas no relatório
□ Substituir colunas calculadas de agregação por medidas

RELATÓRIO
□ Reduzir número de visuais por página (máximo 7)
□ Verificar se há visuais com queries > 5 segundos (Performance Analyzer)
□ Desabilitar interações desnecessárias entre visuais
□ Evitar múltiplos cartões de KPI calculando a mesma base

DAX
□ Identificar medidas sem VAR com cálculos repetidos
□ Substituir divisões diretas por DIVIDE()
□ Verificar se COUNTROWS substitui COUNT()
```

### Análise Abrangente (≈ 2–4 horas)

```text
STORAGE MODE
□ Avaliar tabelas de fato para Dual mode (se usadas em DirectQuery + Import)
□ Configurar tabelas de dimensão como Import
□ Implementar aggregations para tabelas com > 10M linhas

DAX AVANÇADO
□ Usar DAX Studio para analisar query plans
□ Identificar context transitions desnecessárias
□ Avaliar uso de Calculation Groups para reduzir medidas repetidas
□ Revisar uso de FILTER() vs. condições diretas no CALCULATE

REFRESH
□ Configurar Incremental Refresh para fatos históricos
□ Revisar queries redundantes no Power Query
□ Desabilitar "Include in report refresh" em queries de referência
□ Avaliar partition strategy para modelos volumosos
```

---

## 15. Design de Relatório — Framework de Consulta {#design-framework}

### Levantamento de Requisitos

```text
CONTEXTO DE NEGÓCIO
□ Qual problema de negócio será resolvido?
□ Quem é o público-alvo? (Executivos / Analistas / Operadores)
□ Quais decisões este relatório irá apoiar?
□ Quais são os KPIs prioritários?
□ Como o relatório será acessado? (Desktop / Mobile / TV / Apresentação)

DADOS E TÉCNICA
□ Quais fontes de dados estão disponíveis?
□ Qual é a granularidade dos dados? (transacional / agregado / tempo real)
□ Há restrições de segurança (RLS)?
□ Qual frequência de atualização é necessária?
```

### Checklist de Design Review

```text
LAYOUT E HIERARQUIA
□ KPI cards proeminentes no topo da página
□ Máximo 5–7 visuais por página
□ Hierarquia visual clara: KPIs → Gráficos → Tabela/Detalhe
□ Espaçamento consistente entre visuais (16px ou 24px)

ACESSIBILIDADE
□ Contraste mínimo 4.5:1 entre texto e fundo
□ Paleta colorblind-friendly (sem verde/vermelho sem ícone adicional)
□ Alt text em visuais críticos
□ Teste em Phone Layout (mobile)

INTERATIVIDADE
□ Bookmarks para alternar entre visões (ex: Vendas vs. Lucro)
□ Drill-through configurado para páginas de detalhe
□ Tooltips customizados com contexto adicional
□ Slicers com seleção padrão definida

TEMA
□ Paleta de cores semântica consistente
□ Tipografia hierárquica (título > subtítulo > corpo > rótulo)
□ Sem overrides visuais individuais que contradizem o tema
□ Theme JSON versionado no repositório PBIP
```

### Seleção de Visuais — Referência Rápida

```text
TENDÊNCIA TEMPORAL          → Line Chart
COMPARAÇÃO DE CATEGORIAS    → Bar / Column Chart
DISTRIBUIÇÃO GEOGRÁFICA     → Map / Filled Map
KPI / RESUMO EXECUTIVO      → Card Visual / KPI
ANÁLISE DE CAUSA-RAIZ       → Decomposition Tree
FATORES DE INFLUÊNCIA       → Key Influencers
ANÁLISE CRUZADA             → Matrix com Conditional Formatting
COMPOSIÇÃO / PROPORÇÃO      → Stacked Bar / Treemap
RANKING                     → Bar Chart ordenado + RANKX
CORRELAÇÃO                  → Scatter Chart
TABELA DE DETALHES          → Table / Matrix com formatação
ANÁLISE TEMPORAL WATERFALL  → Waterfall Chart
```

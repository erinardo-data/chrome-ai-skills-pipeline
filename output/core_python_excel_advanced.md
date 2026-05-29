# core_python_excel_advanced.md
> **Skill consolidada a partir de 21 fontes especializadas** · skills.sh ecosystem  
> Fontes: wshobson/agents · affaan-m/everything-claude-code · davila7/claude-code-templates · sbroenne/mcp-server-excel · mineru98/skills-store · excelsioryy · thepexcel · claude-office-skills  
> **Última compilação:** Maio/2026 · Versão: 1.0.0  
> ⚠️ Este arquivo é complementar ao `core_powerbi_advanced.md` — sem repetições de conteúdo PBI.

---

## 📋 Índice

1. [Resumo Executivo](#resumo-executivo)
2. [Python — Arquitetura e Princípios de Design](#python-design)
3. [Python — Qualidade de Código e Estilo](#python-estilo)
4. [Python — Tipagem e Segurança Estática](#python-tipos)
5. [Python — Tratamento de Erros e Resiliência](#python-erros)
6. [Python — Performance e Otimização](#python-performance)
7. [Python — Observabilidade e Configuração](#python-obs)
8. [Python — Testes e Estrutura de Projeto](#python-testes)
9. [Python — Concorrência e Jobs em Background](#python-async)
10. [Excel — Análise e Automação](#excel)
11. [Design Gráfico para Dados](#design-grafico)
12. [Melhores Práticas — Checklist Executivo](#checklist)
13. [Anti-Padrões a Evitar](#anti-padroes)

---

## 1. Resumo Executivo {#resumo-executivo}

Este arquivo consolida skills de **engenharia Python** e **automação Excel** do ecossistema skills.sh, cobrindo o ciclo completo de desenvolvimento de aplicações de dados robustas e bem estruturadas.

| Domínio | Cobertura |
|---|---|
| **Design de Código** | KISS, SRP, Composição > Herança, Separação de Concerns |
| **Qualidade** | ruff, mypy, PEP 8, docstrings Google-style, imports absolutos |
| **Tipagem** | Type hints, Generics, TypeVar, Protocols, mypy strict |
| **Erros** | Fail-fast, Pydantic validation, hierarquias de exceção |
| **Performance** | cProfile, memory_profiler, py-spy, 20+ padrões de otimização |
| **Observabilidade** | structlog, Prometheus, OpenTelemetry, Correlation IDs |
| **Testes** | pytest, fixtures, mocking, TDD, property-based testing |
| **Resiliência** | tenacity, retry, exponential backoff, circuit breaker |
| **Background Jobs** | Celery, RQ, Dramatiq, idempotência, dead letter queues |
| **Recursos** | Context managers, connection pools, async cleanup |
| **Excel** | pandas, openpyxl, excelcli COM, análise automatizada |

---

## 2. Python — Arquitetura e Princípios de Design {#python-design}

### 2.1 Os 5 Princípios Fundamentais (wshobson/agents)

| Princípio | Definição | Regra prática |
|---|---|---|
| **KISS** | Keep It Simple | Complexidade precisa ser justificada por requisitos concretos |
| **SRP** | Single Responsibility | Uma classe/função, um motivo para mudar |
| **SoC** | Separation of Concerns | API, Service, Repository em camadas distintas |
| **Composição > Herança** | Prefira `has-a` a `is-a` | Use protocolos e injeção de dependência |
| **Rule of Three** | Não abstraia antes de ver 3 repetições | Evite premature abstraction |

### 2.2 Arquitetura em Camadas

```
┌─────────────────────────┐
│  API Layer              │  ← Validação de entrada, serialização
├─────────────────────────┤
│  Service Layer          │  ← Lógica de negócio
├─────────────────────────┤
│  Repository Layer       │  ← Acesso a dados (DB, API externa)
├─────────────────────────┤
│  Domain Models          │  ← Entidades e Value Objects
└─────────────────────────┘
```

- Dependências fluem **de cima para baixo** — nunca de baixo para cima
- Injeção de dependência via construtores — facilita testes
- Cada camada conhece apenas a interface da camada abaixo

### 2.3 Padrões Pythônicos Essenciais (affaan-m)

- **EAFP** (Easier to Ask Forgiveness than Permission) em vez de LBYL
- **Context managers** para todos os recursos (`with` statement)
- **Generators** para sequências grandes — evite carregar tudo em memória
- **Dataclasses** para objetos de dados simples e estruturados
- **Decorators** para cross-cutting concerns (log, retry, cache)

---

## 3. Python — Qualidade de Código e Estilo {#python-estilo}

### 3.1 Ferramentas Obrigatórias

| Ferramenta | Função | Substitui |
|---|---|---|
| **ruff** | Linting + formatação unificado | flake8 + isort + black |
| **mypy** ou **pyright** | Checagem estática de tipos | — |
| **pytest** | Testes | unittest |
| **pre-commit** | Hooks de qualidade no git | — |

### 3.2 Convenções de Nomenclatura (PEP 8)

| Objeto | Padrão | Exemplo |
|---|---|---|
| Funções e variáveis | `snake_case` | `calculate_total` |
| Classes | `PascalCase` | `OrderProcessor` |
| Constantes | `SCREAMING_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| Módulos/pacotes | `snake_case` | `data_pipeline` |
| Privado | `_prefixo` | `_internal_method` |
| Muito privado | `__prefixo` | `__secret` |

### 3.3 Docstrings — Padrão Google

- Todas as funções e classes públicas **obrigatoriamente documentadas**
- Seções: `Args`, `Returns`, `Raises`, `Example`
- Funções internas (`_`) podem ser mais sucintas

### 3.4 Organização de Imports

```
# 1. Biblioteca padrão
import os
import sys

# 2. Terceiros
import pandas as pd
import structlog

# 3. Locais (absolutos — nunca relativos em projetos)
from myapp.services import OrderService
```

---

## 4. Python — Tipagem e Segurança Estática {#python-tipos}

### 4.1 Hierarquia de Uso de Tipos

```
1. Funções públicas        → type hints obrigatórios
2. Retornos complexos      → TypedDict ou dataclass
3. Genéricos reutilizáveis → TypeVar + Generic[T]
4. Interfaces estruturais  → Protocol (duck typing seguro)
5. Guardas de tipo         → isinstance() + narrowing
```

### 4.2 Tipos Modernos (Python 3.10+)

- `X | Y` em vez de `Union[X, Y]`
- `list[str]` em vez de `List[str]` (minúsculo)
- `dict[str, int]` em vez de `Dict[str, int]`
- `str | None` em vez de `Optional[str]`

### 4.3 Configuração mypy Strict

```ini
# mypy.ini
[mypy]
strict = true
warn_return_any = true
disallow_untyped_defs = true
```

### 4.4 Estratégia de Adoção Incremental

1. Adicionar `# type: ignore` apenas onde estritamente necessário
2. Tipar módulos novos primeiro
3. Gradualmente tipar módulos existentes por camada
4. Ativar `--strict` quando cobertura de tipos atingir ~80%

---

## 5. Python — Tratamento de Erros e Resiliência {#python-erros}

### 5.1 Princípio Fail-Fast

- Validar **todas as entradas** antes de operações custosas
- Reportar **todos os erros de validação** de uma vez (não um por um)
- Usar **Pydantic** para validação de dados externos e APIs

### 5.2 Hierarquia de Exceções

```
BaseAppError
├── ValidationError       ← Dados inválidos (4xx)
│   ├── RequiredFieldError
│   └── FormatError
├── NotFoundError         ← Recurso não existe (404)
├── PermissionError       ← Sem autorização (403)
└── ExternalServiceError  ← Falha em API/DB externos (5xx)
```

- Cada exceção carrega **contexto** suficiente para debug
- Use **exception chaining** (`raise NewError() from original_error`)
- **Nunca** faça `except Exception: pass` — sempre logue ou re-raise

### 5.3 Resiliência com tenacity

| Padrão | Quando usar |
|---|---|
| **Retry básico** | Erros transitórios (timeout, 5xx) |
| **Exponential backoff + jitter** | APIs com rate limiting |
| **Retry seletivo** | Só em exceções específicas |
| **Timeout decorator** | Operações com SLA |
| **Fail-safe default** | Funcionalidades não-críticas |

**Regras de retry:**
- Máximo: 3–5 tentativas (nunca retry infinito)
- Cap de duração total: sempre defina um teto
- **Nunca** retente erros permanentes (400, credenciais inválidas)
- Sempre logue cada tentativa com contexto

---

## 6. Python — Performance e Otimização {#python-performance}

### 6.1 Fluxo de Otimização (never optimize prematurely)

```
1. MEÇA com cProfile / py-spy      ← identifique o gargalo real
2. ANALISE o hot path               ← confirme antes de otimizar
3. OTIMIZE apenas o que mediu       ← cirurgia, não reforma
4. VALIDE com benchmark             ← prove que melhorou
```

### 6.2 Ferramentas de Profiling

| Ferramenta | Tipo | Uso |
|---|---|---|
| `cProfile` | CPU, built-in | Profiling de desenvolvimento |
| `line_profiler` | CPU linha a linha | Hot paths identificados |
| `memory_profiler` | Memória | Uso e leaks de RAM |
| `py-spy` | CPU, produção | Profiling sem reiniciar o processo |
| `tracemalloc` | Memória, built-in | Rastreamento de alocações |
| `pytest-benchmark` | Microbenchmarks | CI/CD regression tests |

### 6.3 20+ Padrões de Otimização (por categoria)

**Estruturas de dados:**
- `set` para lookups em vez de `list` — O(1) vs O(n)
- `dict.get()` em vez de `key in dict` + `dict[key]`
- `collections.deque` para filas — O(1) em ambos os lados

**Código Python:**
- List comprehensions em vez de loops `append`
- Generators para sequências grandes (`yield`)
- `''.join(list)` em vez de concatenação `+=` em loop
- `functools.lru_cache` / `@cache` para resultados repetidos

**I/O e banco de dados:**
- Operações em batch em vez de N+1 queries
- `asyncio` para I/O-bound concorrente
- `multiprocessing` para CPU-bound paralelo
- Indexação e `EXPLAIN` em queries SQL

**NumPy / pandas:**
- Vetorização em vez de loops Python
- `pd.eval()` para cálculos em DataFrames grandes
- Tipos de dados explícitos (`int32` em vez de `int64` quando possível)

---

## 7. Python — Observabilidade e Configuração {#python-obs}

### 7.1 Os Três Pilares da Observabilidade

| Pilar | Ferramenta principal | O que responde |
|---|---|---|
| **Logs** | structlog (JSON) | "O que aconteceu?" |
| **Métricas** | Prometheus | "Com que frequência / intensidade?" |
| **Traces** | OpenTelemetry | "Onde na cadeia de serviços?" |

### 7.2 Os 4 Golden Signals (Prometheus)

- **Latency** — tempo de resposta por percentil (p50, p95, p99)
- **Traffic** — requests por segundo
- **Errors** — taxa de erros (4xx, 5xx)
- **Saturation** — uso de CPU, memória, conexões do pool

### 7.3 Regras de Métricas

- **Bounded cardinality** — nunca use user IDs ou timestamps como labels
- Máximo ~10 valores distintos por label
- Nomes no padrão `namespace_subsystem_name_unit`

### 7.4 Correlation IDs

- Injetar no ingresso da requisição (middleware FastAPI/Django)
- Propagar via headers (`X-Correlation-ID`) entre serviços
- Incluir em **todos** os logs do ciclo de vida da requisição

### 7.5 Configuração com pydantic-settings

- **Toda** configuração em variáveis de ambiente — nunca hardcoded
- Objetos de configuração tipados carregados na **inicialização**
- Settings ausentes e obrigatórios = crash imediato (fail-fast)
- Grupos por subsistema: `DatabaseSettings`, `CacheSettings`, `AppSettings`
- `.env` para desenvolvimento local; secrets montados em produção

---

## 8. Python — Testes e Estrutura de Projeto {#python-testes}

### 8.1 Pirâmide de Testes

```
           ▲  E2E Tests (poucos, lentos)
          ▲▲▲ Integration Tests
         ▲▲▲▲▲ Unit Tests (muitos, rápidos)
```

### 8.2 Padrão AAA (obrigatório em todo teste)

```
Arrange  → preparar dados e dependências
Act      → chamar o código sob teste
Assert   → verificar resultado
```

### 8.3 10 Padrões pytest Essenciais

| Padrão | Quando usar |
|---|---|
| `@pytest.fixture` | Setup/teardown reutilizável |
| `@pytest.mark.parametrize` | Mesmo teste, múltiplas entradas |
| `unittest.mock.patch` | Isolar dependências externas |
| `pytest.raises` | Verificar exceções esperadas |
| `@pytest.mark.asyncio` | Testar código assíncrono |
| `monkeypatch` | Substituir funções/env vars |
| `tmp_path` fixture | Arquivos temporários |
| `freezegun` | Controlar `datetime.now()` |
| `hypothesis` | Property-based testing |
| `pytest-benchmark` | Medir performance em CI |

### 8.4 Estrutura de Projeto (wshobson/agents)

**Por camada (aplicações menores):**
```
myapp/
├── api/          ← rotas e handlers
├── services/     ← lógica de negócio
├── repositories/ ← acesso a dados
├── models/       ← entidades de domínio
└── config.py     ← configuração central
```

**Por domínio (aplicações maiores):**
```
myapp/
├── orders/
│   ├── api.py
│   ├── service.py
│   └── repository.py
├── users/
└── payments/
```

### 8.5 Regras de Módulos

- `__all__` em todo módulo com API pública explícita
- Arquivos com > 300–500 linhas → considere dividir
- Imports **absolutos** exclusivamente
- Sem importações circulares — reorganize se necessário

---

## 9. Python — Concorrência e Jobs em Background {#python-async}

### 9.1 Quando usar cada abordagem

| Problema | Solução |
|---|---|
| I/O-bound concorrente (APIs, DB) | `asyncio` / `async/await` |
| I/O-bound paralelo (threads) | `threading` / `concurrent.futures.ThreadPoolExecutor` |
| CPU-bound paralelo | `multiprocessing` / `ProcessPoolExecutor` |
| Tarefas longas desacopladas | Task queue (Celery, RQ, Dramatiq) |
| Agendamento periódico | Celery Beat / APScheduler |

### 9.2 Padrão Task Queue

```
API → aceita requisição → enfileira job → retorna job_id imediatamente
                                ↓
                        Worker processa assincronamente
                                ↓
                        Cliente faz polling em /jobs/{id}
```

### 9.3 Frameworks de Task Queue

| Framework | Broker | Melhor para |
|---|---|---|
| **Celery** | Redis / RabbitMQ | Projetos grandes, workflows complexos |
| **RQ** | Redis | Simplicidade, projetos menores |
| **Dramatiq** | Redis / RabbitMQ | Tipagem, middleware |
| **AWS SQS** | Managed | Cloud-native, sem ops |

### 9.4 Idempotência em Jobs

- Implementar **check-before-write** antes de cada operação
- Usar **idempotency keys** nas requisições externas
- Definir **deduplication windows** para at-least-once delivery
- Dead Letter Queue (DLQ) para falhas após N retries

### 9.5 Gerenciamento de Recursos

- Context managers para **todos** os recursos (DB, files, sockets)
- `contextlib.ExitStack` para recursos dinâmicos
- `asynccontextmanager` para recursos assíncronos
- Connection pools — nunca abrir/fechar conexões por request

---

## 10. Excel — Análise e Automação {#excel}

### 10.1 Stack por Caso de Uso

| Caso | Ferramenta | Observação |
|---|---|---|
| Ler/transformar dados | **pandas** | Cross-platform |
| Escrever Excel formatado | **openpyxl** | Headers, cores, larguras |
| Automação COM (Windows) | **excelcli** | Requer Excel instalado |
| Análise de qualidade | **excel-data-analyzer** | Relatório automático |
| Pivot tables via código | **pandas.pivot_table** | — |
| Gráficos | **matplotlib** | Exportar para xlsx |

### 10.2 excelcli — Fluxo de Trabalho (Windows apenas)

```
Pré-requisito: Excel 2016+ instalado, COM interop
Instalação: dotnet tool install --global Sbroenne.ExcelMcp.CLI
```

| Etapa | Comando | Obrigatório? |
|---|---|---|
| 1. Criar sessão | `session create/open` | ✅ Sempre primeiro |
| 2. Worksheets | `worksheet create/rename` | Se necessário |
| 3. Escrever dados | (ver exemplos) | Se escrevendo |
| 4. Salvar/fechar | `session close --save` | ✅ Sempre último |

- **Batch mode**: 10+ comandos → usar `excelcli -q batch --input commands.json`
- Elimina overhead de processo por comando
- Session IDs capturados automaticamente no batch

### 10.3 Análise de Dados com pandas

**Fluxo recomendado:**
1. `pd.read_excel()` com `sheet_name` explícito
2. `df.describe()` + `df.info()` para exploração inicial
3. Tratar nulos, duplicatas e tipos **antes** de qualquer análise
4. Selecionar apenas colunas necessárias para performance
5. Usar `chunksize` para arquivos grandes

### 10.4 Diagnóstico de Qualidade de Dados (excel-data-analyzer)

- Identificar inconsistências de formato por coluna
- Detectar valores fora do domínio esperado
- Calcular % de nulos por coluna
- Gerar relatório Markdown com ações recomendadas

---

## 11. Design Gráfico para Dados {#design-grafico}

### 11.1 Princípio Central

> **Design = Comunicação + Estética**  
> Bom design é invisível: guia o olhar, transmite a mensagem e parece "certo" sem esforço.

### 11.2 Hierarquia Visual

1. **Contraste** — diferencie o que é importante
2. **Alinhamento** — crie ordem e estrutura
3. **Repetição** — consistência cria confiança
4. **Proximidade** — agrupe elementos relacionados

### 11.3 Para Dashboards e Relatórios

- Paleta de no máximo **3–5 cores** com papéis semânticos claros
- Tipografia: máximo 2 famílias, hierarquia definida
- Espaço em branco é intencional — não é desperdício
- Cada visual deve responder **uma pergunta específica**

---

## 12. Melhores Práticas — Checklist Executivo {#checklist}

### Python — Qualidade
- [ ] ruff configurado e rodando em pre-commit
- [ ] mypy em modo strict (ou adoção incremental documentada)
- [ ] 100% das funções públicas com type hints
- [ ] Docstrings Google-style em todo código público
- [ ] Imports absolutos em todo o projeto

### Python — Arquitetura
- [ ] Separação clara em camadas (API / Service / Repository)
- [ ] Injeção de dependência nos serviços
- [ ] `__all__` definido em módulos com API pública
- [ ] Sem arquivos > 500 linhas
- [ ] Sem importações circulares

### Python — Produção
- [ ] Toda configuração via variáveis de ambiente
- [ ] Logging estruturado (JSON) com correlation IDs
- [ ] Métricas Prometheus nos 4 golden signals
- [ ] Retry com exponential backoff em chamadas externas
- [ ] Context managers em todos os recursos
- [ ] Testes cobrindo caminhos críticos e edge cases
- [ ] Dead Letter Queue para jobs assíncronos

### Excel
- [ ] Selecionar apenas colunas necessárias ao ler
- [ ] Tratar nulos e tipos antes da análise
- [ ] Usar batch mode no excelcli (10+ operações)
- [ ] Sempre `session close --save` ao terminar
- [ ] Relatório de qualidade antes de análises críticas

---

## 13. Anti-Padrões a Evitar {#anti-padroes}

| Anti-Padrão | Por quê é ruim | Solução Correta |
|---|---|---|
| `except Exception: pass` | Engole erros silenciosamente | Logue e re-raise ou trate explicitamente |
| `except Exception as e: print(e)` | Log sem estrutura, sem contexto | `logger.error("msg", exc_info=True, **context)` |
| `time.sleep()` em retry manual | Loop frágil sem backoff | `tenacity` com `wait_exponential` |
| Configuração hardcoded | Impossível mudar sem deploy | `pydantic-settings` + variáveis de ambiente |
| `import *` | Namespace poluído, dependências ocultas | Imports explícitos e absolutos |
| Herança profunda (> 2 níveis) | Fragilidade, acoplamento forte | Composição + Protocols |
| Funções > 50 linhas sem razão | Difícil testar e entender | Extraia funções menores com SRP |
| Loop `for` com `+=` em strings | O(n²) em tempo e memória | `''.join(lista)` |
| Abrir conexão DB por request | Esgota o pool em picos | Connection pool + context manager |
| Labels de alta cardinalidade em Prometheus | Explosão do storage de métricas | Labels com ≤ 10 valores distintos |
| `pd.read_excel()` sem selecionar colunas | Carrega dados desnecessários | `usecols=` sempre que possível |
| Celery task sem idempotência | Dados duplicados em re-execução | Check-before-write + idempotency keys |
| Abstração prematura | Complexidade sem benefício | Rule of Three — espere 3 repetições |

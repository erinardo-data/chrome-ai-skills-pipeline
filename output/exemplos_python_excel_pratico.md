# exemplos_python_excel_pratico.md
> **Exemplos práticos compilados de 21 fontes especializadas** · skills.sh ecosystem  
> Fontes: wshobson/agents · affaan-m/everything-claude-code · davila7 · sbroenne · mineru98  
> **Última compilação:** Maio/2026 · Versão: 1.0.0  
> ⚠️ Complementar ao `exemplos_powerbi_pratico.md` — sem repetições de conteúdo PBI/DAX/M.

---

## 📋 Índice

1. [Python — Design Patterns](#design-patterns)
2. [Python — Type Safety](#type-safety)
3. [Python — Error Handling](#error-handling)
4. [Python — Resiliência (Retry & Timeout)](#resiliencia)
5. [Python — Performance & Profiling](#performance)
6. [Python — Observabilidade](#observabilidade)
7. [Python — Configuração](#configuracao)
8. [Python — Testes com pytest](#testes)
9. [Python — Concorrência e Background Jobs](#concorrencia)
10. [Python — Gerenciamento de Recursos](#recursos)
11. [Python — Estrutura de Projeto](#estrutura)
12. [Excel — Análise com pandas + openpyxl](#excel-pandas)
13. [Excel — Automação COM com excelcli](#excel-cli)
14. [Excel — Diagnóstico de Qualidade](#excel-qualidade)

---

## 1. Python — Design Patterns {#design-patterns}

### KISS + Single Responsibility

```python
# ❌ ERRADO: uma função fazendo tudo
def process_order(order_id: str, db, email_client, logger):
    order = db.query(f"SELECT * FROM orders WHERE id = '{order_id}'")
    if order["status"] == "pending":
        db.execute(f"UPDATE orders SET status='processing' WHERE id='{order_id}'")
        email_client.send(order["email"], "Seu pedido está sendo processado")
        logger.info(f"Processed {order_id}")
    return order

# ✅ CORRETO: cada responsabilidade em sua própria função/classe
class OrderService:
    def __init__(self, repo: OrderRepository, notifier: Notifier):
        self._repo = repo
        self._notifier = notifier

    def process(self, order_id: str) -> Order:
        order = self._repo.get(order_id)          # busca
        order.mark_as_processing()                 # regra de negócio
        self._repo.save(order)                     # persiste
        self._notifier.order_processing(order)     # notifica
        return order
```

### Composição > Herança

```python
# ❌ ERRADO: herança profunda e frágil
class Animal:
    def breathe(self): ...

class Mammal(Animal):
    def feed_young(self): ...

class Dog(Mammal):
    def bark(self): ...

class ServiceDog(Dog):             # já está difícil de testar
    def assist_human(self): ...

# ✅ CORRETO: composição + protocolos
from typing import Protocol

class Speakable(Protocol):
    def speak(self) -> str: ...

class Trainable(Protocol):
    def execute_command(self, cmd: str) -> bool: ...

class Dog:
    def speak(self) -> str:
        return "Woof"

class CommandTrainer:
    def train(self, animal: Trainable, commands: list[str]) -> None:
        for cmd in commands:
            animal.execute_command(cmd)
```

### EAFP (Pythônico) vs LBYL

```python
# ❌ LBYL — verifica antes de agir (não-pythônico)
if "key" in data and data["key"] is not None:
    value = data["key"]
    result = process(value)

# ✅ EAFP — tenta e trata a exceção
try:
    result = process(data["key"])
except (KeyError, TypeError) as e:
    logger.warning("Missing or null key", error=str(e))
    result = default_value
```

---

## 2. Python — Type Safety {#type-safety}

### Anotações Básicas e Modernos (Python 3.10+)

```python
# Sintaxe moderna — Python 3.10+
def calculate(
    price: float,
    quantity: int,
    discount: float | None = None,  # em vez de Optional[float]
) -> float:
    base = price * quantity
    return base * (1 - discount) if discount else base

# Tipos de coleções sem import
def process_items(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}
```

### Generics com TypeVar

```python
from typing import TypeVar, Generic

T = TypeVar("T")

class Repository(Generic[T]):
    def __init__(self) -> None:
        self._items: list[T] = []

    def add(self, item: T) -> None:
        self._items.append(item)

    def get_all(self) -> list[T]:
        return self._items.copy()

# Uso tipado
order_repo: Repository[Order] = Repository()
order_repo.add(Order(id="1"))     # ✅ tipagem verificada
```

### Protocols (duck typing seguro)

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Serializable(Protocol):
    def to_dict(self) -> dict: ...
    def from_dict(cls, data: dict) -> "Serializable": ...

def save_to_cache(obj: Serializable, key: str) -> None:
    data = obj.to_dict()   # garante que o método existe em compile-time
    cache.set(key, data)
```

### Type Narrowing

```python
from typing import Union

def process(value: str | int | None) -> str:
    if value is None:             # narrowing: value é str | int aqui
        return "empty"
    if isinstance(value, int):    # narrowing: value é int aqui
        return str(value * 2)
    return value.upper()          # narrowing: value é str aqui
```

---

## 3. Python — Error Handling {#error-handling}

### Hierarquia de Exceções customizada

```python
class AppError(Exception):
    """Exceção base da aplicação."""
    def __init__(self, message: str, context: dict | None = None):
        super().__init__(message)
        self.context = context or {}

class ValidationError(AppError):
    """Dados de entrada inválidos."""

class NotFoundError(AppError):
    """Recurso não encontrado."""

class ExternalServiceError(AppError):
    """Falha em serviço externo."""
    def __init__(self, service: str, message: str, original: Exception):
        super().__init__(message, {"service": service})
        self.__cause__ = original   # exception chaining
```

### Fail-Fast com Pydantic

```python
from pydantic import BaseModel, Field, validator

class CreateOrderRequest(BaseModel):
    product_id: str = Field(..., min_length=1)
    quantity: int = Field(..., gt=0, le=1000)
    customer_email: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")

    @validator("product_id")
    def product_must_exist(cls, v):
        if not v.startswith("PROD-"):
            raise ValueError("product_id deve começar com PROD-")
        return v

# Uso: Pydantic reporta TODOS os erros de uma vez
try:
    req = CreateOrderRequest(**request_data)
except ValidationError as e:
    return {"errors": e.errors()}   # lista completa de problemas
```

### Exception Chaining

```python
def fetch_user(user_id: str) -> User:
    try:
        response = http_client.get(f"/users/{user_id}")
        response.raise_for_status()
        return User(**response.json())
    except HTTPError as e:
        raise ExternalServiceError(
            service="users-api",
            message=f"Falha ao buscar usuário {user_id}",
            original=e
        ) from e   # preserva o traceback original
```

---

## 4. Python — Resiliência (Retry & Timeout) {#resiliencia}

### Retry com tenacity

```python
from tenacity import (
    retry, stop_after_attempt, wait_exponential,
    retry_if_exception_type, before_sleep_log
)
import logging

logger = logging.getLogger(__name__)

# Padrão básico
@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10),
    retry=retry_if_exception_type(TransientError),
    before_sleep=before_sleep_log(logger, logging.WARNING),
)
def call_external_api(endpoint: str) -> dict:
    response = requests.get(endpoint, timeout=5)
    response.raise_for_status()
    return response.json()

# Com retry em HTTP status codes específicos
@retry(
    stop=stop_after_attempt(4),
    wait=wait_exponential(multiplier=2, max=30),
    retry=retry_if_result(lambda r: r.status_code in {429, 502, 503, 504}),
)
def resilient_post(url: str, payload: dict) -> requests.Response:
    return requests.post(url, json=payload, timeout=10)
```

### Timeout Decorator

```python
import signal
from functools import wraps

def timeout(seconds: int):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            def handler(signum, frame):
                raise TimeoutError(f"{func.__name__} excedeu {seconds}s")
            signal.signal(signal.SIGALRM, handler)
            signal.alarm(seconds)
            try:
                return func(*args, **kwargs)
            finally:
                signal.alarm(0)
        return wrapper
    return decorator

@timeout(30)
def slow_report_generation(params: dict) -> bytes:
    # operação que não pode demorar mais de 30s
    ...
```

### Fail-Safe Default

```python
from tenacity import retry, stop_after_attempt, RetryError

@retry(stop=stop_after_attempt(2))
def get_recommendations(user_id: str) -> list[str]:
    return external_ml_service.recommend(user_id)

def safe_recommendations(user_id: str) -> list[str]:
    try:
        return get_recommendations(user_id)
    except RetryError:
        logger.warning("Recommendations unavailable, using defaults", user_id=user_id)
        return DEFAULT_RECOMMENDATIONS   # degradação graciosa
```

---

## 5. Python — Performance & Profiling {#performance}

### cProfile + pstats

```python
import cProfile
import pstats
from io import StringIO

def profile_function(func, *args, **kwargs):
    profiler = cProfile.Profile()
    profiler.enable()
    result = func(*args, **kwargs)
    profiler.disable()

    stream = StringIO()
    stats = pstats.Stats(profiler, stream=stream)
    stats.sort_stats("cumulative")
    stats.print_stats(20)     # top 20 funções
    print(stream.getvalue())
    return result
```

### Benchmark Decorator

```python
import time
from functools import wraps
from typing import Callable

def benchmark(func: Callable) -> Callable:
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__}: {elapsed:.4f}s")
        return result
    return wrapper
```

### Padrões de Otimização — Antes vs. Depois

```python
# ❌ String concatenation em loop — O(n²)
result = ""
for item in large_list:
    result += str(item) + ", "

# ✅ join — O(n)
result = ", ".join(str(item) for item in large_list)

# ❌ List como lookup — O(n) por busca
valid_codes = ["A1", "B2", "C3", ...]
if code in valid_codes:   # O(n)
    ...

# ✅ Set como lookup — O(1)
valid_codes = {"A1", "B2", "C3", ...}
if code in valid_codes:   # O(1)
    ...

# ❌ Loop com append
squares = []
for x in range(1000):
    squares.append(x ** 2)

# ✅ List comprehension (mais rápido + legível)
squares = [x ** 2 for x in range(1000)]

# ❌ Recalcular resultado em cada iteração
for item in items:
    if expensive_lookup(item.category) in allowed:   # chamada repetida
        ...

# ✅ Cache com lru_cache
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_lookup(category: str) -> str:
    ...
```

### Detecção de Memory Leaks com tracemalloc

```python
import tracemalloc

tracemalloc.start()

# ... código suspeito ...

snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics("lineno")
for stat in top_stats[:10]:
    print(stat)
```

---

## 6. Python — Observabilidade {#observabilidade}

### Logging Estruturado com structlog

```python
import structlog

logger = structlog.get_logger()

# Configuração para produção (JSON)
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.stdlib.add_log_level,
        structlog.processors.JSONRenderer(),
    ]
)

# Uso com contexto rico
def process_order(order_id: str, user_id: str) -> None:
    log = logger.bind(order_id=order_id, user_id=user_id)

    log.info("processing_started")
    try:
        result = do_work(order_id)
        log.info("processing_completed", duration_ms=result.duration)
    except Exception as e:
        log.error("processing_failed", error=str(e), exc_info=True)
        raise
```

### Métricas Prometheus

```python
from prometheus_client import Counter, Histogram, Gauge

# Definição dos instrumentos
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total de requisições HTTP",
    ["method", "endpoint", "status_code"],   # labels de baixa cardinalidade
)

REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "Duração das requisições",
    ["endpoint"],
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)

ACTIVE_CONNECTIONS = Gauge(
    "db_active_connections",
    "Conexões ativas no pool",
)

# FastAPI middleware de instrumentação
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    with REQUEST_DURATION.labels(endpoint=request.url.path).time():
        response = await call_next(request)
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status_code=response.status_code,
    ).inc()
    return response
```

### Correlation IDs com FastAPI

```python
import uuid
from contextvars import ContextVar

correlation_id: ContextVar[str] = ContextVar("correlation_id", default="")

@app.middleware("http")
async def correlation_middleware(request: Request, call_next):
    cid = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    correlation_id.set(cid)

    response = await call_next(request)
    response.headers["X-Correlation-ID"] = cid
    return response
```

---

## 7. Python — Configuração {#configuracao}

### pydantic-settings

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class DatabaseSettings(BaseSettings):
    host: str = Field(..., description="DB host")
    port: int = Field(5432)
    name: str = Field(..., description="DB name")
    password: str = Field(..., description="DB password")  # obrigatório

    model_config = SettingsConfigDict(env_prefix="DB_")

class AppSettings(BaseSettings):
    debug: bool = False
    log_level: str = "INFO"
    database: DatabaseSettings = DatabaseSettings()

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

# Singleton de configuração — falha rápido na inicialização
settings = AppSettings()   # lança ValidationError se algo obrigatório faltar
```

### Configuração por Ambiente

```python
from enum import Enum

class Environment(str, Enum):
    DEV = "development"
    STAGING = "staging"
    PROD = "production"

class Config(BaseSettings):
    env: Environment = Environment.DEV
    database_url: str
    redis_url: str
    secret_key: str

    @property
    def is_production(self) -> bool:
        return self.env == Environment.PROD

    @property
    def log_level(self) -> str:
        return "WARNING" if self.is_production else "DEBUG"
```

---

## 8. Python — Testes com pytest {#testes}

### Fixtures e Setup

```python
import pytest
from unittest.mock import MagicMock, patch

@pytest.fixture
def mock_db():
    db = MagicMock()
    db.query.return_value = [{"id": "1", "name": "Test"}]
    return db

@pytest.fixture
def order_service(mock_db):
    notifier = MagicMock()
    return OrderService(repo=mock_db, notifier=notifier)
```

### Parametrize

```python
@pytest.mark.parametrize("price,quantity,discount,expected", [
    (100.0, 2, None,  200.0),
    (100.0, 2, 0.1,   180.0),
    (50.0,  3, 0.2,   120.0),
])
def test_calculate(price, quantity, discount, expected):
    assert calculate(price, quantity, discount) == expected
```

### Mocking de Dependências Externas

```python
@patch("myapp.services.requests.get")
def test_fetch_user_success(mock_get):
    mock_get.return_value.status_code = 200
    mock_get.return_value.json.return_value = {"id": "1", "name": "Alice"}

    user = fetch_user("1")

    assert user.name == "Alice"
    mock_get.assert_called_once_with("/users/1")

def test_fetch_user_not_found(mock_get):
    mock_get.return_value.status_code = 404
    mock_get.return_value.raise_for_status.side_effect = HTTPError("404")

    with pytest.raises(NotFoundError):
        fetch_user("999")
```

### Teste Assíncrono

```python
import pytest

@pytest.mark.asyncio
async def test_async_processor():
    processor = AsyncProcessor()
    result = await processor.process({"id": "1"})
    assert result.status == "completed"
```

### Property-Based Testing com Hypothesis

```python
from hypothesis import given, strategies as st

@given(
    price=st.floats(min_value=0.01, max_value=1e6),
    quantity=st.integers(min_value=1, max_value=1000),
)
def test_calculate_never_negative(price, quantity):
    result = calculate(price, quantity)
    assert result >= 0   # invariante: resultado nunca negativo
```

---

## 9. Python — Concorrência e Background Jobs {#concorrencia}

### asyncio para I/O-bound

```python
import asyncio
import httpx

async def fetch_all(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient(timeout=10) as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)

    results = []
    for url, resp in zip(urls, responses):
        if isinstance(resp, Exception):
            logger.error("fetch_failed", url=url, error=str(resp))
        else:
            results.append(resp.json())
    return results
```

### Celery — Task Queue

```python
from celery import Celery
from celery.utils.log import get_task_logger

app = Celery("myapp", broker="redis://localhost:6379/0")
logger = get_task_logger(__name__)

@app.task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,
    acks_late=True,          # idempotência: só confirma após sucesso
)
def process_report(self, report_id: str) -> dict:
    try:
        # Check-before-write para idempotência
        if Report.objects.filter(id=report_id, status="done").exists():
            logger.info("report_already_processed", report_id=report_id)
            return {"status": "skipped"}

        result = generate_report(report_id)
        return {"status": "done", "output": result}

    except TransientError as exc:
        logger.warning("retrying_task", report_id=report_id, retry=self.request.retries)
        raise self.retry(exc=exc)
```

### API com retorno imediato + polling

```python
from fastapi import FastAPI, BackgroundTasks
import uuid

app = FastAPI()
job_store: dict[str, dict] = {}

@app.post("/reports")
async def create_report(params: ReportParams, background_tasks: BackgroundTasks):
    job_id = str(uuid.uuid4())
    job_store[job_id] = {"status": "queued"}
    background_tasks.add_task(run_report, job_id, params)
    return {"job_id": job_id}   # retorna imediatamente

@app.get("/reports/{job_id}")
async def get_report_status(job_id: str):
    return job_store.get(job_id, {"status": "not_found"})
```

---

## 10. Python — Gerenciamento de Recursos {#recursos}

### Context Manager de Conexão DB

```python
from contextlib import contextmanager
from typing import Generator

@contextmanager
def get_db_connection() -> Generator[Connection, None, None]:
    conn = pool.acquire()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        pool.release(conn)   # SEMPRE liberado, mesmo em exceções

# Uso
with get_db_connection() as conn:
    conn.execute("INSERT INTO orders ...")
```

### Context Manager Assíncrono

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def managed_session(client: AsyncClient):
    session = await client.create_session()
    try:
        yield session
    finally:
        await session.close()   # cleanup garantido

async def process():
    async with managed_session(http_client) as session:
        data = await session.get("/api/data")
```

### ExitStack para Recursos Dinâmicos

```python
from contextlib import ExitStack

def process_multiple_files(paths: list[str]) -> None:
    with ExitStack() as stack:
        files = [
            stack.enter_context(open(p, "r"))
            for p in paths
        ]
        # todos os arquivos abertos; todos serão fechados ao sair
        for f in files:
            process(f.read())
```

### Streaming com Acumulação Eficiente

```python
from dataclasses import dataclass, field
import time

@dataclass
class StreamState:
    chunks: list[str] = field(default_factory=list)
    total_tokens: int = 0
    start_time: float = field(default_factory=time.perf_counter)
    first_chunk_time: float | None = None

    def add_chunk(self, chunk: str) -> None:
        if self.first_chunk_time is None:
            self.first_chunk_time = time.perf_counter() - self.start_time
        self.chunks.append(chunk)
        self.total_tokens += len(chunk.split())

    def result(self) -> str:
        return "".join(self.chunks)   # O(n) — eficiente
```

---

## 11. Python — Estrutura de Projeto {#estrutura}

### Layout por Camada (projetos menores)

```
myapp/
├── __init__.py
├── api/
│   ├── __init__.py        # __all__ = ["router"]
│   ├── routes.py
│   └── schemas.py
├── services/
│   ├── __init__.py        # __all__ = ["OrderService"]
│   └── order_service.py
├── repositories/
│   ├── __init__.py
│   └── order_repo.py
├── models/
│   ├── __init__.py
│   └── order.py
├── config.py
└── main.py

tests/
├── unit/
│   └── test_order_service.py
├── integration/
│   └── test_order_api.py
└── conftest.py            # fixtures compartilhadas
```

### pyproject.toml com ruff + mypy

```toml
[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "UP", "B", "SIM"]
ignore = ["E501"]
target-version = "py310"

[tool.ruff.per-file-ignores]
"tests/*" = ["S101"]   # permite assert em testes

[tool.mypy]
strict = true
python_version = "3.10"
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

### Módulo com `__all__` explícito

```python
# myapp/services/__init__.py
from .order_service import OrderService
from .payment_service import PaymentService

__all__ = ["OrderService", "PaymentService"]
# membros não listados permanecem como detalhes de implementação
```

---

## 12. Excel — Análise com pandas + openpyxl {#excel-pandas}

### Leitura e Exploração

```python
import pandas as pd

# Leitura eficiente — selecione apenas o que precisa
df = pd.read_excel(
    "data.xlsx",
    sheet_name="Vendas",
    usecols=["Data", "Produto", "Quantidade", "Valor"],
    dtype={"Quantidade": "int32", "Valor": "float64"},
)

# Exploração inicial obrigatória antes de qualquer análise
print(df.info())         # tipos, nulos, memória
print(df.describe())     # estatísticas descritivas
print(df.isnull().sum()) # contagem de nulos por coluna
```

### Limpeza de Dados

```python
# Pipeline de limpeza encadeado
df_clean = (
    df
    .dropna(subset=["Produto", "Valor"])   # remove nulos críticos
    .drop_duplicates(subset=["OrderID"])    # remove duplicatas
    .assign(
        Data=pd.to_datetime(df["Data"], dayfirst=True),
        Valor=df["Valor"].abs(),            # garante positivo
        Produto=df["Produto"].str.strip().str.upper(),
    )
    .query("Valor > 0")                    # remove zeros/negativos
    .reset_index(drop=True)
)
```

### Pivot Table

```python
# Vendas por produto e mês
pivot = pd.pivot_table(
    df_clean,
    values="Valor",
    index="Produto",
    columns=pd.Grouper(key="Data", freq="ME"),
    aggfunc="sum",
    fill_value=0,
    margins=True,
    margins_name="Total",
)

print(pivot.round(2))
```

### Escrita Formatada com openpyxl

```python
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

def write_formatted_excel(df: pd.DataFrame, path: str) -> None:
    with pd.ExcelWriter(path, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="Dados", index=False)
        ws = writer.sheets["Dados"]

        # Cabeçalho em negrito com fundo azul
        header_fill = PatternFill("solid", fgColor="366092")
        header_font = Font(color="FFFFFF", bold=True)
        for cell in ws[1]:
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal="center")

        # Auto-ajustar largura das colunas
        for col_idx, col in enumerate(df.columns, 1):
            max_len = max(df[col].astype(str).str.len().max(), len(col)) + 2
            ws.column_dimensions[get_column_letter(col_idx)].width = max_len
```

### Merge de Múltiplos Arquivos

```python
from pathlib import Path

def merge_excel_files(folder: str, pattern: str = "*.xlsx") -> pd.DataFrame:
    files = list(Path(folder).glob(pattern))
    if not files:
        raise FileNotFoundError(f"Nenhum arquivo encontrado em {folder}")

    dfs = []
    for f in files:
        df = pd.read_excel(f, usecols=["Data", "Produto", "Valor"])
        df["source_file"] = f.name
        dfs.append(df)

    return pd.concat(dfs, ignore_index=True)
```

### Leitura em Chunks (arquivos grandes)

```python
# Para arquivos com 100k+ linhas
chunks = pd.read_excel(
    "large_data.xlsx",
    chunksize=10_000,    # processa 10k linhas por vez
    usecols=["ID", "Valor"],
)

total = sum(chunk["Valor"].sum() for chunk in chunks)
```

---

## 13. Excel — Automação COM com excelcli {#excel-cli}

### Instalação e Setup

```bash
# Pré-requisito: Windows + Excel 2016+
dotnet tool install --global Sbroenne.ExcelMcp.CLI

# Verificar instalação
excelcli --version
```

### Workflow Básico

```bash
# 1. Criar sessão (sempre primeiro)
SESSION_ID=$(excelcli session create --file "report.xlsx")
echo "Session: $SESSION_ID"

# 2. Criar worksheet
excelcli worksheet create --session $SESSION_ID --name "Vendas"

# 3. Escrever dados
excelcli range write --session $SESSION_ID \
  --sheet "Vendas" --range "A1" \
  --data '[["Produto","Jan","Fev","Mar"],["Caneta",100,120,115]]'

# 4. Criar tabela formatada
excelcli table create --session $SESSION_ID \
  --sheet "Vendas" --range "A1:D3" --name "TabelaVendas"

# 5. Adicionar gráfico
excelcli chart create --session $SESSION_ID \
  --sheet "Vendas" --type "ColumnClustered" \
  --data-range "A1:D3" --title "Vendas por Mês"

# 6. Fechar e salvar (sempre último)
excelcli session close --session $SESSION_ID --save
```

### Batch Mode (10+ operações)

```json
// commands.json
{
  "commands": [
    {"action": "session.create", "file": "output.xlsx"},
    {"action": "worksheet.create", "name": "Dashboard"},
    {"action": "range.write", "sheet": "Dashboard", "range": "A1",
     "data": [["KPI", "Valor", "Meta"],["Vendas", 150000, 120000]]},
    {"action": "table.create", "sheet": "Dashboard",
     "range": "A1:C3", "name": "KPITable"},
    {"action": "session.close", "save": true}
  ]
}
```

```bash
excelcli -q batch --input commands.json
```

---

## 14. Excel — Diagnóstico de Qualidade {#excel-qualidade}

### Script de Análise Automática

```python
import pandas as pd
from pathlib import Path

def analyze_excel_quality(path: str) -> str:
    """Gera relatório Markdown de qualidade do arquivo Excel."""
    xl = pd.ExcelFile(path)
    report = [f"# Relatório de Qualidade: {Path(path).name}\n"]

    for sheet in xl.sheet_names:
        df = pd.read_excel(xl, sheet_name=sheet)
        report.append(f"## Aba: {sheet}")
        report.append(f"- **Linhas:** {len(df):,} | **Colunas:** {len(df.columns)}")
        report.append(f"- **Memória:** {df.memory_usage(deep=True).sum() / 1024:.1f} KB\n")

        # Análise por coluna
        report.append("### Qualidade por Coluna\n")
        report.append("| Coluna | Tipo | Nulos | % Nulos | Únicos |")
        report.append("|--------|------|-------|---------|--------|")
        for col in df.columns:
            nulls = df[col].isnull().sum()
            pct = nulls / len(df) * 100
            uniq = df[col].nunique()
            report.append(
                f"| {col} | {df[col].dtype} | {nulls} | {pct:.1f}% | {uniq} |"
            )

        # Duplicatas
        dupes = df.duplicated().sum()
        if dupes > 0:
            report.append(f"\n⚠️ **{dupes} linhas duplicadas detectadas**")

        report.append("")

    return "\n".join(report)

# Uso
report_md = analyze_excel_quality("vendas_2026.xlsx")
Path("quality_report.md").write_text(report_md, encoding="utf-8")
print(report_md)
```

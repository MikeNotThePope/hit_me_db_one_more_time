# Hit Me DB One More Time

An MCP (Model Context Protocol) Server with a plugin architecture for demonstrating rate limiting concepts.

## Features

- **MCP Server**: Full JSON-RPC 2.0 implementation over stdio
- **Plugin Architecture**: Middleware pipeline that intercepts requests before hitting the database
- **Rate Limiting**: Fixed-window rate limiter (5 requests per 10 seconds)
- **Caching Layer**: Response caching with 30-second TTL
- **SQLite Database**: 100 sample records with pagination support
- **Comprehensive Tests**: 28 tests covering all components

## Architecture

```
┌─────────────┐
│ MCP Client  │
└──────┬──────┘
       │ JSON-RPC 2.0
       ▼
┌─────────────────────────────────┐
│     MCP Server (stdio)          │
│  - Protocol Handler             │
│  - Tool Registry                │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│    Plugin Pipeline              │
│  ┌────────────────────────┐    │
│  │ 1. Rate Limiter        │    │
│  │    (5 req/10s)         │    │
│  │    ├─ if exceeded ──┐  │    │
│  │    │                │  │    │
│  │    ▼                │  │    │
│  │ 2. Logging Plugin   │  │    │
│  │    (logs requests)  │  │    │
│  │    ▼                │  │    │
│  │ 3. Cache Plugin     │  │    │
│  │    (30s TTL)        │  │    │
│  │    ├─ if hit ───┐   │  │    │
│  │    │            │   │  │    │
│  └────┼────────────┼───┼──┘    │
│       │            │   │        │
│       ▼            │   │        │
│   Database         │   │        │
│       │            │   │        │
│       └────────────┴───┴────────┤
│                                 │
│     All short-circuits exit ────┤
│     and return response here    │
└─────────────────────────────────┘
       │
       ▼
   Response to Client
```

## Installation

```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Run tests
mix test
```

## Running the Server

```bash
# Start the MCP server
mix run --no-halt
```

The server communicates over stdio using JSON-RPC 2.0 protocol.

## Available Tools

### `get_records`

Retrieve N records from the database with pagination support.

**Parameters:**
- `limit` (number, optional): Number of records to fetch (default: 10, max: 100)
- `offset` (number, optional): Number of records to skip (default: 0)

**Example Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "get_records",
    "arguments": {
      "limit": 10,
      "offset": 0
    }
  }
}
```

**Example Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"items\": [\n    {\n      \"id\": 1,\n      \"name\": \"Item 1\",\n      \"description\": \"This is a sample item...\",\n      \"created_at\": \"2024-01-20T12:00:00Z\"\n    }\n  ],\n  \"pagination\": {\n    \"limit\": 10,\n    \"offset\": 0,\n    \"total\": 100,\n    \"has_more\": true\n  }\n}"
      }
    ]
  }
}
```

## Plugin Architecture

The plugin system allows intercepting requests before they hit the database. This is perfect for implementing:
- Rate limiting
- Caching
- Authentication
- Request validation
- Logging and monitoring

### How Plugins Work

Each plugin implements the `HitMeDbOneMoreTime.Plugins.Behaviour` and can:

1. **Pass through**: Let the request continue to the next plugin
2. **Short-circuit**: Return a response immediately without hitting the database
3. **Update context**: Modify the shared context for downstream plugins

### Example: Cache Plugin

The cache plugin demonstrates how to short-circuit requests for rate limiting:

```elixir
def process(request, context) do
  cache_key = generate_cache_key(request)

  case get_from_cache(cache_key) do
    {:ok, cached_response} ->
      # Short-circuit! Return cached response without hitting DB
      Logger.info("[Cache Plugin] Cache HIT")
      {:respond, cached_response}

    :miss ->
      # Pass to next plugin/handler
      Logger.info("[Cache Plugin] Cache MISS")
      {:pass, Map.put(context, :cache_key, cache_key)}
  end
end
```

### Example: Rate Limiter Plugin

The rate limiter plugin demonstrates request counting and denial:

```elixir
def process(request, context) do
  client_id = extract_client_id(request, context)

  case check_rate_limit(client_id, max_requests, window_seconds) do
    {:ok, current_count} ->
      # Within limits - pass through
      Logger.info("[Rate Limiter] Request allowed (#{current_count}/#{max_requests})")
      {:pass, Map.put(context, :rate_limit_current, current_count)}

    {:error, :rate_limit_exceeded, retry_after} ->
      # Exceeded - short-circuit with error
      Logger.warning("[Rate Limiter] Rate limit exceeded")
      {:respond, %{
        "error" => "rate_limit_exceeded",
        "message" => "Too many requests. Please try again later.",
        "details" => %{
          "limit" => max_requests,
          "retry_after_seconds" => retry_after
        }
      }}
  end
end
```

**Key Features:**
- **Fixed window algorithm**: 5 requests per 10-second window
- **ETS storage**: In-memory tracking per client/tool
- **Automatic reset**: Counter resets after window expires
- **Short-circuit on limit**: Returns error without touching database or cache

**Configuration:**

You can customize rate limits via context:
```elixir
context = %{
  rate_limit_max: 10,       # 10 requests
  rate_limit_window: 60     # per 60 seconds
}
```

### Adding Your Own Plugin

1. Create a new module implementing the behaviour:

```elixir
defmodule MyPlugin do
  @behaviour HitMeDbOneMoreTime.Plugins.Behaviour

  def process(request, context) do
    # Your logic here
    :pass  # or {:respond, response} or {:pass, updated_context}
  end
end
```

2. Add it to the pipeline in `lib/hit_me_db_one_more_time/mcp/tools.ex`:

```elixir
plugins = [
  RateLimiterPlugin,  # Check rate limits first
  LoggingPlugin,      # Log allowed requests
  CachePlugin,        # Check cache for allowed requests
  MyPlugin            # <-- Add your plugin
]
```

**Plugin execution order matters!** Rate limiter runs first to reject over-limit requests before they're even logged.

## Project Structure

```
lib/
├── hit_me_db_one_more_time/
│   ├── application.ex          # OTP application supervisor
│   ├── mcp/
│   │   ├── server.ex           # MCP server (stdio communication)
│   │   ├── protocol.ex         # JSON-RPC 2.0 handling
│   │   └── tools.ex            # Tool implementations
│   ├── plugins/
│   │   ├── behaviour.ex            # Plugin contract
│   │   ├── pipeline.ex             # Plugin execution engine
│   │   ├── rate_limiter_plugin.ex  # Rate limiting (fixed window)
│   │   ├── logging_plugin.ex       # Request logging
│   │   └── cache_plugin.ex         # Response caching (30s TTL)
│   └── database/
│       ├── repo.ex             # Ecto repository
│       ├── item.ex             # Item schema
│       └── seeder.ex           # Sample data generator
└── hit_me_db_one_more_time.ex # Main module
```

## Testing

```bash
# Run all tests
mix test

# Run with detailed output
mix test --trace

# Run specific test file
mix test test/plugins/pipeline_test.exs

# Check code formatting
mix format --check-formatted
```

## Development

```bash
# Start interactive shell with project loaded
iex -S mix

# Try calling tools directly
iex> HitMeDbOneMoreTime.MCP.Tools.execute_tool("get_records", %{"limit" => 5})
```

## For Your Blog Post

This server demonstrates a complete rate limiting implementation with these key concepts:

### 1. **Plugin Pipeline Architecture**
Requests flow through a middleware pipeline where each plugin can:
- Inspect the request
- Short-circuit and return early
- Pass context to downstream plugins
- Modify or reject requests

### 2. **Rate Limiting Implementation**
The `RateLimiterPlugin` demonstrates:
- **Fixed window algorithm**: Tracks requests in time windows (5 req/10s)
- **ETS storage**: Fast in-memory counters per client
- **Automatic expiration**: Windows reset after time period
- **Graceful degradation**: Returns retry-after time in errors

### 3. **Multi-Layer Defense**
```
Request → Rate Limiter → Logger → Cache → Database
          └─ Denies      └─ Logs  └─ Serves  └─ Fetches
             excessive      only      cached      fresh
             requests      allowed    results     data
```

### 4. **Benefits of This Approach**

**Performance**:
- Rate-limited requests never hit the database
- Cached responses skip database entirely
- Logging only records allowed requests

**Scalability**:
- ETS provides microsecond lookups
- No external dependencies needed for basic rate limiting
- Easy to replace ETS with Redis for distributed systems

**Observability**:
- Structured logging at each layer
- Rate limit metrics in response context
- Clear error messages with retry guidance

### 5. **Production Considerations**

For production use, you'd enhance this with:
- **Sliding window** algorithm for smoother rate limiting
- **Redis** for distributed rate limiting across servers
- **Per-user/API-key** tracking instead of per-tool
- **Different limits** for different endpoints or user tiers
- **Rate limit headers** (X-RateLimit-Limit, X-RateLimit-Remaining)
- **Graceful degradation** strategies when rate limit storage fails

## License

This is a demonstration project for blog post purposes.

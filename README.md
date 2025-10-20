# Hit Me DB One More Times

An MCP (Model Context Protocol) Server with a plugin architecture for demonstrating rate limiting concepts.

## Features

- **MCP Server**: Full JSON-RPC 2.0 implementation over stdio
- **Plugin Architecture**: Middleware pipeline that intercepts requests before hitting the database
- **SQLite Database**: 100 sample records with pagination support
- **Caching Plugin**: Demonstrates request interception for rate limiting
- **Comprehensive Tests**: Full test coverage for all components

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
│  │ 1. Logging Plugin      │    │
│  │    (logs requests)     │    │
│  └───────────┬────────────┘    │
│              ▼                  │
│  ┌────────────────────────┐    │
│  │ 2. Cache Plugin        │    │
│  │    (short-circuits     │    │
│  │     on cache hit)      │    │
│  └───────────┬────────────┘    │
│              │                  │
└──────────────┼──────────────────┘
               │ (cache miss)
               ▼
       ┌───────────────┐
       │ SQLite DB     │
       │ (100 items)   │
       └───────────────┘
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

Each plugin implements the `HitMeDbOneMoreTimes.Plugins.Behaviour` and can:

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

For rate limiting, you would check request rates here and either:
- Serve from cache if within rate limits
- Deny the request if rate limit exceeded
- Pass through if rate limit not reached

### Adding Your Own Plugin

1. Create a new module implementing the behaviour:

```elixir
defmodule MyPlugin do
  @behaviour HitMeDbOneMoreTimes.Plugins.Behaviour

  def process(request, context) do
    # Your logic here
    :pass  # or {:respond, response} or {:pass, updated_context}
  end
end
```

2. Add it to the pipeline in `lib/hit_me_db_one_more_times/mcp/tools.ex`:

```elixir
plugins = [
  LoggingPlugin,
  CachePlugin,
  MyPlugin  # <-- Add your plugin
]
```

## Project Structure

```
lib/
├── hit_me_db_one_more_times/
│   ├── application.ex          # OTP application supervisor
│   ├── mcp/
│   │   ├── server.ex           # MCP server (stdio communication)
│   │   ├── protocol.ex         # JSON-RPC 2.0 handling
│   │   └── tools.ex            # Tool implementations
│   ├── plugins/
│   │   ├── behaviour.ex        # Plugin contract
│   │   ├── pipeline.ex         # Plugin execution engine
│   │   ├── logging_plugin.ex   # Logging example
│   │   └── cache_plugin.ex     # Caching example (rate limit foundation)
│   └── database/
│       ├── repo.ex             # Ecto repository
│       ├── item.ex             # Item schema
│       └── seeder.ex           # Sample data generator
└── hit_me_db_one_more_times.ex # Main module
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
iex> HitMeDbOneMoreTimes.MCP.Tools.execute_tool("get_records", %{"limit" => 5})
```

## For Your Blog Post

This server demonstrates key concepts for rate limiting:

1. **Request Interception**: The plugin pipeline intercepts all requests before they reach the database
2. **Short-circuiting**: Plugins can serve responses without hitting the database
3. **Shared Context**: Plugins can pass information to each other through the context
4. **Caching Layer**: The cache plugin shows how to store and retrieve results

To implement rate limiting, you would:
1. Add a rate limiting plugin that tracks request counts per client
2. Check if the rate limit is exceeded
3. If exceeded, short-circuit with an error response
4. If not exceeded, pass through and increment the counter
5. Optionally serve from cache to reduce database load

## License

This is a demonstration project for blog post purposes.

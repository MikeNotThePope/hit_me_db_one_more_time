defmodule HitMeDbOneMoreTime do
  @moduledoc """
  An MCP (Model Context Protocol) Server with a plugin architecture for request processing.

  This server demonstrates:
  - JSON-RPC 2.0 communication over stdio
  - Plugin middleware pipeline for intercepting requests
  - SQLite database integration with pagination
  - Caching layer for rate limiting demonstration

  ## Architecture

  - **MCP Server**: Handles JSON-RPC protocol and tool execution
  - **Plugin System**: Middleware pipeline that can intercept and modify requests
  - **Database Layer**: SQLite with Ecto for data persistence
  - **Tools**: `get_records` - Fetch N records with pagination

  ## Running the Server

      # Fetch dependencies
      mix deps.get

      # Compile
      mix compile

      # Start the server
      mix run --no-halt

  ## Testing with MCP Inspector

  You can test this server using the MCP Inspector or any MCP-compatible client.

  Example request:
  ```json
  {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "get_records", "arguments": {"limit": 10, "offset": 0}}}
  ```
  """

  @doc """
  Hello world function for testing.

  ## Examples

      iex> HitMeDbOneMoreTime.hello()
      :world

  """
  def hello do
    :world
  end
end

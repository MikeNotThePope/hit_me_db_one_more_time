defmodule HitMeDbOneMoreTimes.MCP.Server do
  @moduledoc """
  MCP Server that communicates over stdio using JSON-RPC 2.0.

  This server implements the Model Context Protocol, allowing clients to:
  - Discover available tools
  - Execute tools with parameters
  - Receive structured responses
  """

  use GenServer
  require Logger

  alias HitMeDbOneMoreTimes.MCP.{Protocol, Tools}

  @server_info %{
    "name" => "hit_me_db_one_more_times",
    "version" => "0.1.0"
  }

  @capabilities %{
    "tools" => %{}
  }

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("MCP Server starting...")

    # Send initialization notification
    send_output(Protocol.notification("server/initialized", %{}))

    # Start reading from stdin in a separate process
    spawn_link(fn -> read_loop() end)

    {:ok, %{initialized: false}}
  end

  @impl true
  def handle_info({:request, line}, state) do
    case Protocol.parse_request(line) do
      {:ok, request} ->
        response = handle_request(request, state)
        send_output(response)
        {:noreply, state}

      {:error, reason} ->
        Logger.error("Failed to parse request: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  ## Private Functions

  defp read_loop do
    case IO.gets("") do
      :eof ->
        Logger.info("Received EOF, shutting down...")
        System.halt(0)

      {:error, reason} ->
        Logger.error("Error reading from stdin: #{inspect(reason)}")
        System.halt(1)

      line ->
        line = String.trim(line)

        unless line == "" do
          send(__MODULE__, {:request, line})
        end

        read_loop()
    end
  end

  defp send_output(message) do
    IO.puts(message)
  end

  defp handle_request(%{"method" => "initialize"} = request, _state) do
    id = Map.get(request, "id")

    result = %{
      "protocolVersion" => "2024-11-05",
      "serverInfo" => @server_info,
      "capabilities" => @capabilities
    }

    Protocol.success_response(id, result)
  end

  defp handle_request(%{"method" => "tools/list"} = request, _state) do
    id = Map.get(request, "id")
    tools = Tools.list_tools()

    Protocol.success_response(id, %{"tools" => tools})
  end

  defp handle_request(%{"method" => "tools/call"} = request, _state) do
    id = Map.get(request, "id")
    params = Map.get(request, "params", %{})
    tool_name = Map.get(params, "name")
    arguments = Map.get(params, "arguments", %{})

    try do
      result = Tools.execute_tool(tool_name, arguments)

      Protocol.success_response(id, %{
        "content" => [
          %{
            "type" => "text",
            "text" => Jason.encode!(result, pretty: true)
          }
        ]
      })
    rescue
      error ->
        Logger.error("Error executing tool: #{inspect(error)}")
        Protocol.error_response(id, -32603, "Internal error", inspect(error))
    end
  end

  defp handle_request(%{"method" => method} = request, _state) do
    id = Map.get(request, "id")
    Logger.warning("Unknown method: #{method}")
    Protocol.error_response(id, -32601, "Method not found: #{method}")
  end

  defp handle_request(request, _state) do
    id = Map.get(request, "id")
    Logger.warning("Invalid request: #{inspect(request)}")
    Protocol.error_response(id, -32600, "Invalid request")
  end
end

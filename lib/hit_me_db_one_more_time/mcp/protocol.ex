defmodule HitMeDbOneMoreTime.MCP.Protocol do
  @moduledoc """
  Handles JSON-RPC 2.0 protocol for MCP (Model Context Protocol).
  """

  @doc """
  Parse a JSON-RPC request from a string.
  """
  def parse_request(json_string) do
    case Jason.decode(json_string) do
      {:ok, request} -> {:ok, request}
      {:error, reason} -> {:error, {:invalid_json, reason}}
    end
  end

  @doc """
  Create a JSON-RPC success response.
  """
  def success_response(id, result) do
    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "result" => result
    }
    |> Jason.encode!()
  end

  @doc """
  Create a JSON-RPC error response.
  """
  def error_response(id, code, message, data \\ nil) do
    error = %{
      "code" => code,
      "message" => message
    }

    error =
      if data do
        Map.put(error, "data", data)
      else
        error
      end

    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => error
    }
    |> Jason.encode!()
  end

  @doc """
  Create a notification (response with no id for events).
  """
  def notification(method, params) do
    %{
      "jsonrpc" => "2.0",
      "method" => method,
      "params" => params
    }
    |> Jason.encode!()
  end
end

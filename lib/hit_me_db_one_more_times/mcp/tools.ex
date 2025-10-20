defmodule HitMeDbOneMoreTimes.MCP.Tools do
  @moduledoc """
  Implements MCP tools that can be called by clients.

  This module defines the available tools and their handlers.
  """

  alias HitMeDbOneMoreTimes.Database.{Repo, Item}
  alias HitMeDbOneMoreTimes.Plugins.{Pipeline, LoggingPlugin, CachePlugin}
  import Ecto.Query

  @doc """
  List all available tools with their schemas.
  """
  def list_tools do
    [
      %{
        "name" => "get_records",
        "description" => "Retrieve N records from the database with pagination support",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "limit" => %{
              "type" => "number",
              "description" => "Number of records to fetch (default: 10, max: 100)",
              "default" => 10
            },
            "offset" => %{
              "type" => "number",
              "description" => "Number of records to skip (default: 0)",
              "default" => 0
            }
          }
        }
      }
    ]
  end

  @doc """
  Execute a tool with the given request through the plugin pipeline.
  """
  def execute_tool(tool_name, arguments) do
    request = %{
      "name" => tool_name,
      "arguments" => arguments
    }

    # Define the plugin pipeline
    plugins = [
      LoggingPlugin,
      CachePlugin
    ]

    # Execute through the pipeline
    Pipeline.execute(plugins, request, &handle_tool/2)
  end

  # Private handler that actually executes the tool (called after plugins pass)
  defp handle_tool(request, context) do
    tool_name = Map.get(request, "name")
    arguments = Map.get(request, "arguments")

    result =
      case tool_name do
        "get_records" -> get_records(arguments)
        _ -> {:error, "Unknown tool: #{tool_name}"}
      end

    # Cache the result if we have a cache key from the pipeline
    if cache_key = Map.get(context, :cache_key) do
      CachePlugin.cache_response(cache_key, result)
    end

    result
  end

  defp get_records(arguments) do
    limit = Map.get(arguments, "limit", 10) |> min(100)
    offset = Map.get(arguments, "offset", 0) |> max(0)

    query =
      from i in Item,
        order_by: [desc: i.id],
        limit: ^limit,
        offset: ^offset

    items = Repo.all(query)

    total_count = Repo.aggregate(Item, :count)

    %{
      "items" => Enum.map(items, &serialize_item/1),
      "pagination" => %{
        "limit" => limit,
        "offset" => offset,
        "total" => total_count,
        "has_more" => offset + limit < total_count
      }
    }
  end

  defp serialize_item(item) do
    %{
      "id" => item.id,
      "name" => item.name,
      "description" => item.description,
      "created_at" => DateTime.to_iso8601(item.created_at)
    }
  end
end

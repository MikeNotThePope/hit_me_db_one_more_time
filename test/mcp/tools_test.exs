defmodule HitMeDbOneMoreTimes.MCP.ToolsTest do
  use ExUnit.Case

  alias HitMeDbOneMoreTimes.MCP.Tools
  alias HitMeDbOneMoreTimes.Database.{Repo, Item}

  setup do
    # Ensure the repo is started
    start_supervised!(HitMeDbOneMoreTimes.Database.Repo)

    # Initialize cache
    HitMeDbOneMoreTimes.Plugins.CachePlugin.start_link()

    # Create table and seed test data
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    """)

    Repo.delete_all(Item)

    for i <- 1..25 do
      %Item{}
      |> Item.changeset(%{
        name: "Test Item #{i}",
        description: "Description #{i}",
        created_at: DateTime.utc_now()
      })
      |> Repo.insert!()
    end

    :ok
  end

  describe "list_tools/0" do
    test "returns list of available tools" do
      tools = Tools.list_tools()

      assert is_list(tools)
      assert length(tools) > 0

      get_records_tool = Enum.find(tools, &(&1["name"] == "get_records"))
      assert get_records_tool["description"]
      assert get_records_tool["inputSchema"]
    end
  end

  describe "execute_tool/2 with get_records" do
    test "fetches records with default pagination" do
      result = Tools.execute_tool("get_records", %{})

      assert is_map(result)
      assert is_list(result["items"])
      assert length(result["items"]) == 10
      assert result["pagination"]["limit"] == 10
      assert result["pagination"]["offset"] == 0
      assert result["pagination"]["total"] == 25
      assert result["pagination"]["has_more"] == true
    end

    test "respects custom limit" do
      result = Tools.execute_tool("get_records", %{"limit" => 5})

      assert length(result["items"]) == 5
      assert result["pagination"]["limit"] == 5
    end

    test "respects offset for pagination" do
      result = Tools.execute_tool("get_records", %{"limit" => 5, "offset" => 10})

      assert length(result["items"]) == 5
      assert result["pagination"]["offset"] == 10
    end

    test "limits maximum records to 100" do
      result = Tools.execute_tool("get_records", %{"limit" => 200})

      assert result["pagination"]["limit"] == 100
    end

    test "returns has_more false on last page" do
      result = Tools.execute_tool("get_records", %{"limit" => 20, "offset" => 20})

      assert result["pagination"]["has_more"] == false
    end

    test "items have required fields" do
      result = Tools.execute_tool("get_records", %{"limit" => 1})

      item = List.first(result["items"])
      assert item["id"]
      assert item["name"]
      assert item["description"]
      assert item["created_at"]
    end
  end
end

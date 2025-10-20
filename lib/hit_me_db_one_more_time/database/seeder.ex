defmodule HitMeDbOneMoreTime.Database.Seeder do
  @moduledoc """
  Seeds the database with sample data for demonstration purposes.
  """

  alias HitMeDbOneMoreTime.Database.{Repo, Item}

  @doc """
  Creates the items table if it doesn't exist and seeds it with sample data.
  """
  def seed do
    create_table()
    seed_items(100)
  end

  defp create_table do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    """)
  end

  defp seed_items(count) do
    # Clear existing data
    Repo.delete_all(Item)

    # Insert sample items
    items =
      for i <- 1..count do
        %{
          name: "Item #{i}",
          description: "This is a sample item number #{i} for testing pagination and rate limiting.",
          created_at: DateTime.utc_now() |> DateTime.add(-i * 3600, :second)
        }
      end

    Enum.each(items, fn item_attrs ->
      %Item{}
      |> Item.changeset(item_attrs)
      |> Repo.insert!()
    end)

    IO.puts("Seeded #{count} items successfully!")
  end
end

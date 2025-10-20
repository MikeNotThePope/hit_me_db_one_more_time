defmodule HitMeDbOneMoreTime.Application do
  @moduledoc """
  The main application supervisor for the MCP Server.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Hit Me DB One More Time application...")

    # Initialize plugin ETS tables
    HitMeDbOneMoreTime.Plugins.CachePlugin.start_link()
    HitMeDbOneMoreTime.Plugins.RateLimiterPlugin.start_link()

    children = [
      # Start the Ecto repository
      HitMeDbOneMoreTime.Database.Repo,
      # Start the MCP server
      HitMeDbOneMoreTime.MCP.Server
    ]

    opts = [strategy: :one_for_one, name: HitMeDbOneMoreTime.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Seed the database if it's empty
    Task.start(fn ->
      :timer.sleep(500)
      seed_if_needed()
    end)

    result
  end

  defp seed_if_needed do
    alias HitMeDbOneMoreTime.Database.{Repo, Item, Seeder}

    case Repo.aggregate(Item, :count) do
      0 ->
        Logger.info("Database is empty, seeding...")
        Seeder.seed()

      count ->
        Logger.info("Database already has #{count} items, skipping seed")
    end
  rescue
    error ->
      Logger.warning("Could not check database, seeding anyway: #{inspect(error)}")
      HitMeDbOneMoreTime.Database.Seeder.seed()
  end
end

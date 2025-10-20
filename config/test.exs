import Config

# Configure test database
config :hit_me_db_one_more_times, HitMeDbOneMoreTimes.Database.Repo,
  database: "hit_me_db_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning

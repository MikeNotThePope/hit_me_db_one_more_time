import Config

# Configure test database
config :hit_me_db_one_more_time, HitMeDbOneMoreTime.Database.Repo,
  database: "hit_me_db_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning

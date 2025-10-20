import Config

config :hit_me_db_one_more_times, HitMeDbOneMoreTimes.Database.Repo,
  database: "hit_me_db.sqlite3",
  pool_size: 5

config :hit_me_db_one_more_times,
  ecto_repos: [HitMeDbOneMoreTimes.Database.Repo]

# Import environment specific config
import_config "#{config_env()}.exs"

import Config

config :hit_me_db_one_more_time, HitMeDbOneMoreTime.Database.Repo,
  database: "hit_me_db.sqlite3",
  pool_size: 5

config :hit_me_db_one_more_time,
  ecto_repos: [HitMeDbOneMoreTime.Database.Repo]

# Import environment specific config
import_config "#{config_env()}.exs"

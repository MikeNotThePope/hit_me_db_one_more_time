defmodule HitMeDbOneMoreTimes.Database.Repo do
  use Ecto.Repo,
    otp_app: :hit_me_db_one_more_times,
    adapter: Ecto.Adapters.SQLite3
end

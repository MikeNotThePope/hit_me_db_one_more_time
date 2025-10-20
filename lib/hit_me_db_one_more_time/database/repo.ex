defmodule HitMeDbOneMoreTime.Database.Repo do
  use Ecto.Repo,
    otp_app: :hit_me_db_one_more_time,
    adapter: Ecto.Adapters.SQLite3
end

defmodule HitMeDbOneMoreTimes.MixProject do
  use Mix.Project

  def project do
    [
      app: :hit_me_db_one_more_times,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    extra_applications = [:logger]

    # Don't auto-start the app in test environment
    if Mix.env() == :test do
      [extra_applications: extra_applications]
    else
      [
        extra_applications: extra_applications,
        mod: {HitMeDbOneMoreTimes.Application, []}
      ]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.17"}
    ]
  end
end

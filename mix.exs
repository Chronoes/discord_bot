defmodule DiscordBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :discord_bot,
      version: "0.4.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DiscordBot, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:nostrum, "~> 0.10.0"},
      {:req, "~> 0.3.0"},
      {:jason, "~> 1.4.1"},
      {:sched_ex, "~> 1.1.4"},
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.18"}
    ]
  end
end

defmodule DiscordBot do
  use Application

  # See https://hexdocs.pm/elixir/main/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children =
      Enum.concat([
        [
          DiscordBot.Repo,
          DiscordBot.Consumer,
          DiscordBot.Bosses,
          DiscordBot.Competition
        ],
        DiscordBot.Countdown.tasks()
      ])

    # See https://hexdocs.pm/elixir/main/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DiscordBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

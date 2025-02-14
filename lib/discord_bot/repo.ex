defmodule DiscordBot.Repo do
  use Ecto.Repo,
    otp_app: :discord_bot,
    adapter: Ecto.Adapters.SQLite3
end

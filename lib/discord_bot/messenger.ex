defmodule DiscordBot.Messenger do
  require Logger

  def send_to_me(message) do
    case Nostrum.Api.User.create_dm(Application.get_env(:discord_bot, :my_id)) do
      {:ok, %Nostrum.Struct.Channel{id: channel_id}} ->
        Nostrum.Api.Message.create(
          channel_id,
          message
        )

      {:error, reason} ->
        Logger.error("Failed to create DM channel: #{inspect(reason)}")
    end
  end
end

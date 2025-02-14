defmodule DiscordBot.MessageHandler do
  require Logger
  alias Nostrum.Struct.Message
  alias DiscordBot.Guilds

  def handle_message(%Message{channel_id: channel_id} = message) do
    channel = Guilds.get_guild_channel(channel_id)

    if channel do
      handle_actions_for_message(channel.actions, message)
    end
  end

  defp handle_actions_for_message(actions, message) do
    if Enum.member?(actions, :competition) do
      handle_competition_message(message)
    end

    if Enum.member?(actions, :deaths) do
      handle_deaths_message(message)
    end
  end

  defp handle_competition_message(%Message{id: msg_id, channel_id: channel_id} = message) do
    case DiscordBot.Competition.check_message(message) do
      :noop ->
        :noop

      {:ok, comp_id} ->
        DiscordBot.Competition.update_player_datapoints(comp_id)
        Nostrum.Api.Message.react(channel_id, msg_id, "✅")
    end
  end

  defp handle_deaths_message(%Message{id: msg_id, channel_id: channel_id} = message) do
    case DiscordBot.Deaths.parse_deaths_from_message(message) do
      :noop ->
        :ok

      :oof ->
        Logger.info("Death recorded #{msg_id}")
        Nostrum.Api.Message.react(channel_id, msg_id, "💀")
    end
  end
end

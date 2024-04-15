defmodule DiscordBot.MessageHandler do
  require Logger
  alias Nostrum.Struct.Message

  def handle_message(%Message{guild_id: guild_id, channel_id: channel_id} = message) do
    actions = DiscordBot.State.get_channel_actions(guild_id, channel_id)

    if Enum.member?(actions, :competition) do
      handle_competition_message(message)
    end
  end

  defp handle_competition_message(%Message{id: msg_id, channel_id: channel_id} = message) do
    case DiscordBot.Competition.check_message(message) do
      :noop ->
        :noop

      {:ok, comp_id} ->
        DiscordBot.Competition.update_player_datapoints(comp_id)
        Nostrum.Api.create_reaction(channel_id, msg_id, "✅")
    end
  end
end

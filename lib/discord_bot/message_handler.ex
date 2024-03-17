defmodule DiscordBot.MessageHandler do
  require Logger
  alias Nostrum.Struct.Message

  def handle_message(%Message{channel_id: channel_id} = message) do
    if DiscordBot.State.is_registered_channel(channel_id) do
      handle_channel_message(message)
    end
  end

  defp handle_channel_message(%Message{content: content} = _message) do
    if String.contains?(content, "templeosrs.com/competitions") do
      case Regex.run(~r/id=(\d+)/, content) do
        [_, comp_id] ->
          DiscordBot.Competition.update_player_datapoints(comp_id)

        _ ->
          :noop
      end
    end
  end
end

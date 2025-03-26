defmodule DiscordBot.MessageHandler do
  require Logger
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.Event.{MessageDelete, MessageDeleteBulk}
  alias DiscordBot.Guilds

  @spec handle_message(Message.t()) :: :ok | Nostrum.Api.error()
  def handle_message(%Message{channel_id: channel_id} = message) do
    channel = Guilds.get_guild_channel(channel_id)

    if channel do
      if Enum.member?(channel.actions, :competition) do
        handle_competition_message(message)
      end

      if Enum.member?(channel.actions, :deaths) do
        handle_deaths_message(message)
      end
    end
  end

  @spec handle_delete_message(MessageDelete.t() | MessageDeleteBulk.t()) ::
          :ok | Nostrum.Api.error()
  def handle_delete_message(%{channel_id: channel_id} = message) do
    channel = Guilds.get_guild_channel(channel_id)

    if channel do
      if Enum.member?(channel.actions, :deaths) do
        handle_deaths_message(message)
      end
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
    case DiscordBot.Deaths.add_deaths_from_message(message) do
      :noop ->
        :ok

      :oof ->
        Logger.info("Death recorded #{msg_id}")
        Nostrum.Api.Message.react(channel_id, msg_id, "💀")
    end
  end

  defp handle_deaths_message(message) do
    msg_ids =
      case message do
        %MessageDelete{id: id} -> [id]
        %MessageDeleteBulk{ids: ids} -> ids
      end

    msg_ids
    |> DiscordBot.Deaths.remove_deaths()

    Logger.info("Deaths removed #{Enum.join(msg_ids, ", ")}")
    :ok
  end
end

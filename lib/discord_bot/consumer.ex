defmodule DiscordBot.Consumer do
  use Nostrum.Consumer
  require Logger

  alias Nostrum.Api

  def handle_event({:READY, event, _ws_state}) do
    %{guilds: guilds} = event

    guilds
    |> Enum.each(fn guild -> DiscordBot.Commands.create_commands(guild.id) end)
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    DiscordBot.MessageHandler.handle_message(message)
  end

  def handle_event({:MESSAGE_DELETE, message, _ws_state}) do
    DiscordBot.MessageHandler.handle_delete_message(message)
  end

  def handle_event({:MESSAGE_DELETE_BULK, message, _ws_state}) do
    DiscordBot.MessageHandler.handle_delete_message(message)
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    case DiscordBot.Commands.handle_interaction(interaction) do
      {:deferred, build_data} ->
        # Discord requires an initial response within 3s, so acknowledge with
        # DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE ("Bot is thinking...") and edit it once done.
        # The interaction token stays valid for 15 minutes.
        Api.create_interaction_response(interaction, %{type: 5})

        data =
          try do
            build_data.()
          rescue
            e ->
              Logger.error(Exception.format(:error, e, __STACKTRACE__))
              %{content: "**Something went wrong**"}
          end

        Api.Interaction.edit_response(interaction, data)

      response ->
        Api.create_interaction_response(interaction, response)
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end

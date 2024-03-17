defmodule DiscordBot.Consumer do
  use Nostrum.Consumer
  require Logger

  alias Nostrum.Api

  @behaviour Nostrum.Consumer
  def handle_event({:READY, event, _ws_state}) do
    %{guilds: guilds} = event

    guilds
    |> Enum.each(fn guild -> DiscordBot.Commands.create_commands(guild.id) end)
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    DiscordBot.MessageHandler.handle_message(message)
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    response = DiscordBot.Commands.handle_interaction(interaction)
    Api.create_interaction_response(interaction, response)
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end

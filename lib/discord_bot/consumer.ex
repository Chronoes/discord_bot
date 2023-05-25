defmodule DiscordBot.Consumer do
  use Nostrum.Consumer
  require Logger

  alias Nostrum.Api

  @behaviour Nostrum.Consumer
  def handle_event({:READY, event, _ws_state}) do
    %{guilds: guilds} = event
    Logger.info(guilds)

    guilds
    |> Enum.each(fn guild -> DiscordBot.Commands.create_commands(guild.id) end)
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    # Run the command, and check for a response message, or default to a checkmark emoji
    response = DiscordBot.Commands.handle_interaction(interaction)

    Api.create_interaction_response(interaction, response)
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end

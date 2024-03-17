defmodule DiscordBot.State do
  use Agent
  alias Nostrum.Struct.Channel

  @type player :: String.t()
  defstruct players: [],
            channels: []

  @type t :: %__MODULE__{
          players: [player()],
          channels: [Channel.id()]
        }

  defp save_state(%__MODULE__{} = state) do
    File.write!(
      Application.get_env(:discord_bot, :state_config_path),
      Jason.encode!(state)
    )

    state
  end

  defp load_file do
    data = Jason.decode!(File.read!(Application.get_env(:discord_bot, :state_config_path)))
    %__MODULE__{players: data["players"], channels: data["channels"]}
  end

  def start_link(_init) do
    Agent.start_link(
      fn ->
        load_file()
      end,
      name: __MODULE__
    )
  end

  @spec reload_from_file() :: :ok
  def reload_from_file do
    Agent.update(__MODULE__, fn _state ->
      load_file()
    end)
  end

  @spec players :: [player()]
  def players do
    Agent.get(__MODULE__, & &1.players)
  end

  @spec set_players([player()]) :: :ok
  def set_players(players) do
    Agent.update(__MODULE__, fn state ->
      save_state(%__MODULE__{state | players: players})
    end)
  end

  @spec is_registered_channel(Channel.id()) :: boolean()
  def is_registered_channel(channel_id) do
    Agent.get(__MODULE__, & &1.channels)
    |> Enum.member?(channel_id)
  end
end

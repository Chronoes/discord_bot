defmodule DiscordBot.State do
  use Agent
  alias Nostrum.Struct.{Channel, Guild}

  @type player :: String.t()
  @type channel :: %{id: Channel.id(), actions: [atom()]}
  @type guild :: %{id: Guild.id(), commands: [String.t()], channels: %{Channel.id() => channel()}}
  defstruct players: [],
            guilds: %{}

  @type t :: %__MODULE__{
          players: [player()],
          guilds: %{Guild.id() => guild()}
        }

  defp save_state(%__MODULE__{} = state) do
    File.write!(
      Application.get_env(:discord_bot, :state_config_path),
      Jason.encode!(
        state
        |> Map.put(
          :guilds,
          Map.values(state.guilds)
          |> Enum.map(fn guild ->
            guild |> Map.put(:channels, Map.values(guild.channels))
          end)
        )
      )
    )

    state
  end

  defp load_file do
    data = Jason.decode!(File.read!(Application.get_env(:discord_bot, :state_config_path)))

    guilds =
      Enum.reduce(data["guilds"], %{}, fn guild, acc ->
        channels =
          Enum.reduce(guild["channels"], %{}, fn channel, acc ->
            Map.put(acc, channel["id"], %{
              id: channel["id"],
              actions: Enum.map(channel["actions"], &String.to_atom/1)
            })
          end)

        Map.put(acc, guild["id"], %{
          id: guild["id"],
          commands: guild["commands"],
          channels: channels
        })
      end)

    %__MODULE__{players: data["players"], guilds: guilds}
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

  def get_registered_guilds() do
    Agent.get(__MODULE__, fn state ->
      state.guilds
    end)
  end

  @spec get_channel_actions(Guild.id(), Channel.id()) :: [atom()]
  def get_channel_actions(guild_id, channel_id) do
    Agent.get(__MODULE__, fn state ->
      case state.guilds[guild_id] do
        nil ->
          []

        guild ->
          case guild.channels[channel_id] do
            nil -> []
            channel -> channel.actions
          end
      end
    end)
  end

  @spec get_guild_commands(Guild.id()) :: [String.t()]
  def get_guild_commands(guild_id) do
    Agent.get(__MODULE__, fn state ->
      case state.guilds[guild_id] do
        nil ->
          []

        guild ->
          guild.commands
      end
    end)
  end
end

defmodule DiscordBot.State do
  use Agent

  @type player :: String.t()
  defstruct players: []

  @type t :: %__MODULE__{
          players: [player()]
        }

  def start_link(_init) do
    Agent.start_link(
      fn ->
        {:ok, _} = :dets.open_file(:players, [])

        players =
          :dets.traverse(:players, fn player -> {:continue, player} end) |> Enum.map(&elem(&1, 0))

        :dets.close(:players)
        %__MODULE__{players: players}
      end,
      name: __MODULE__
    )
  end

  @spec players :: [player()]
  def players do
    Agent.get(__MODULE__, & &1.players)
  end

  @spec set_players([player()]) :: :ok
  def set_players(players) do
    Agent.update(__MODULE__, fn state ->
      :dets.open_file(:players, [])
      :dets.insert(:players, Enum.map(players, fn p -> {p} end))
      :dets.close(:players)
      %__MODULE__{state | players: players}
    end)
  end
end

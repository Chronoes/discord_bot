defmodule DiscordBot.Competition do
  use Agent
  require Logger
  alias DiscordBot.TempleOsrs

  def start_link(_init) do
    Agent.start_link(
      fn ->
        %{in_progress: false}
      end,
      name: __MODULE__
    )
  end

  @spec fetch_members(binary()) :: [binary()]
  def fetch_members(comp_id) do
    response = TempleOsrs.fetch_competition_members(comp_id)
    response.body
  end

  @spec update_player_datapoints(String.t()) :: :ok
  def update_player_datapoints(comp_id) do
    Agent.update(
      __MODULE__,
      fn
        state when state.in_progress ->
          Logger.info("Competition #{state.in_progress} datapoint update already in progress")
          state

        state ->
          Task.start(fn ->
            players = fetch_members(comp_id)

            Logger.info(
              "Updating datapoints for #{Enum.count(players)} members of competition #{comp_id}"
            )

            Enum.each(players, fn player ->
              try do
                TempleOsrs.add_player_datapoint(player)
              rescue
                _ -> Logger.error("Failed to update datapoint for player #{player}")
              end

              Process.sleep(13_000)
            end)

            Logger.info("Competition #{comp_id} datapoint update complete")
            Agent.update(__MODULE__, fn state -> %{state | in_progress: false} end)
          end)

          %{state | in_progress: comp_id}
      end
    )
  end
end

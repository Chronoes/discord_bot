defmodule DiscordBot.Competition do
  require Logger
  alias DiscordBot.TempleOsrs

  @spec fetch_members(binary()) :: [binary()]
  def fetch_members(comp_id) do
    response = TempleOsrs.fetch_competition_members(comp_id)
    response.body
  end

  def update_player_datapoints(comp_id) do
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
    end)
  end
end

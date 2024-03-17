defmodule DiscordBot.TempleOsrs do
  @api_url "https://templeosrs.com"
  @headers [
    user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/116.0"
  ]

  @spec fetch_player_stats(binary()) :: Req.Response.t()
  def fetch_player_stats(player) do
    Req.get!("#{@api_url}/api/player_stats.php?player=#{URI.encode(player)}&bosses=1",
      headers: @headers
    )
  end

  @spec fetch_competition_members(binary()) :: Req.Response.t()
  def fetch_competition_members(comp_id) do
    Req.get!("#{@api_url}/api/compmembers.php?id=#{URI.encode(comp_id)}",
      headers: @headers
    )
  end

  @spec add_player_datapoint(binary()) :: Req.Response.t()
  def add_player_datapoint(player_id) do
    Req.get!("#{@api_url}/php/add_datapoint.php?player=#{URI.encode(player_id)}",
      headers: @headers
    )
  end
end

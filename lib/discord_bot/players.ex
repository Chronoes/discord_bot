defmodule DiscordBot.Players do
  require Ecto.Query
  alias DiscordBot.Repo
  alias DiscordBot.Players.{Player, Death}

  def get_all_players() do
    Repo.all(Player)
  end

  @spec get_or_create(String.t(), String.t() | nil) :: %Player{}
  def get_or_create(name, group \\ nil) do
    case get_player_by_name(name) do
      nil -> create_player(name, group)
      player -> player
    end
  end

  @spec get_player_by_name(String.t()) :: %Player{} | nil
  def get_player_by_name(name) do
    lc_name = normalize_name(name)

    Ecto.Query.from(p in Player, where: p.name == ^lc_name)
    |> Repo.one()
  end

  @spec create_player(String.t(), String.t() | nil) :: %Player{}
  def create_player(name, group) do
    %Player{}
    |> Player.changeset(%{name: normalize_name(name), display_name: name, group: group})
    |> Repo.insert!()
  end

  @spec normalize_name(String.t()) :: String.t()
  def normalize_name(name) do
    String.downcase(name) |> String.replace(" ", "_")
  end

  @spec get_death_count_by_player() :: [{%Player{}, integer}]
  def get_death_count_by_player() do
    Ecto.Query.from(d in Death,
      preload: :player,
      select: {d, count(d.id)},
      group_by: d.player_id
    )
    |> Repo.all()
    |> Enum.map(fn {death, count} -> {death.player, count} end)
  end
end

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

  @spec get_death_count_by_player() :: [{%Player{}, {integer, integer}}]
  @spec get_death_count_by_player(Date.t() | nil) :: [{%Player{}, {integer, integer}}]
  def get_death_count_by_player(date \\ nil) do
    qry =
      Ecto.Query.from(d in Death,
        preload: :player,
        select: {d, count(d.id), fragment("SUM(CASE WHEN ? THEN 1 ELSE 0 END)", d.is_pk)},
        group_by: d.player_id
      )

    if date do
      Ecto.Query.where(qry, [d], d.timestamp <= ^DateTime.new!(date, ~T[00:00:00]))
    else
      qry
    end
    |> Repo.all()
    |> Enum.map(fn {death, count, pk_count} -> {death.player, {count - pk_count, pk_count}} end)
  end
end

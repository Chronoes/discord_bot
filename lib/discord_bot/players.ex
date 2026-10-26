defmodule DiscordBot.Players do
  require Logger
  require Ecto.Query
  alias DiscordBot.Repo
  alias DiscordBot.Bosses
  alias DiscordBot.TempleOsrs
  alias DiscordBot.Players.{Player, Death, FormerMembership}

  @fetch_concurrency 10
  @fetch_timeout 30_000

  def get_all_players() do
    Repo.all(Player) |> Repo.preload(:former_memberships)
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

  @spec update_player_name(%Player{}, String.t()) :: %Player{}
  def update_player_name(%Player{} = player, new_name) do
    player
    |> Player.changeset(%{name: normalize_name(new_name), display_name: new_name})
    |> Repo.update!()
  end

  @spec add_to_group(String.t(), String.t()) :: {:ok, %Player{}} | {:error, String.t()}
  def add_to_group(name, group) do
    case get_or_create(name) do
      %Player{group: nil} = player ->
        {:ok, player |> Player.changeset(%{group: group}) |> Repo.update!()}

      %Player{group: ^group} = player ->
        {:ok, player}

      %Player{group: other_group} ->
        {:error, "Already in group #{other_group}, remove first"}
    end
  end

  @doc """
  Removes player from their group.

  ## Options

    * `:freeze` - store the player's current boss KC as their contribution to the group,
      so that further KC doesn't count towards it. Defaults to `true`.
    * `:date` - `Date` or `DateTime` to freeze KC at instead of now. Uses the latest
      TempleOSRS datapoint at or before it. A `Date` means midnight UTC.
  """
  @spec remove_from_group(String.t(), keyword()) :: {:ok, %Player{}} | {:error, String.t()}
  def remove_from_group(name, opts \\ []) do
    freeze = Keyword.get(opts, :freeze, true)

    date =
      case Keyword.get(opts, :date) do
        %Date{} = date -> DateTime.new!(date, ~T[00:00:00])
        date -> date
      end

    case get_player_by_name(name) do
      nil ->
        {:error, "Unknown player"}

      %Player{group: nil} ->
        {:error, "Not in a group"}

      %Player{} = player when not freeze ->
        {:ok, player |> Player.changeset(%{group: nil}) |> Repo.update!()}

      %Player{} = player ->
        bosses =
          if date,
            do: Bosses.fetch_player_bosses_at(player.display_name, date),
            else: Bosses.fetch_player_bosses(player.display_name)

        with {:ok, bosses} <- bosses do
          Repo.transaction(fn ->
            %FormerMembership{}
            |> FormerMembership.changeset(%{
              player_id: player.id,
              group: player.group,
              bosses: bosses,
              left_at: DateTime.truncate(date || DateTime.utc_now(), :second)
            })
            |> Repo.insert!()

            player |> Player.changeset(%{group: nil}) |> Repo.update!()
          end)
        end
    end
  end

  @spec refresh_game_mode(%Player{}) :: :ok | {:error, String.t()}
  def refresh_game_mode(%Player{} = player) do
    case TempleOsrs.fetch_player_info(player.display_name) do
      %{body: %{"data" => %{"Game mode" => game_mode, "GIM" => gim_mode}}} ->
        mode = Ecto.Enum.mappings(Player, :game_mode) |> Enum.find(&(elem(&1, 1) == game_mode))

        if mode do
          player
          |> Player.changeset(%{game_mode: elem(mode, 0), gim_mode: gim_mode})
          |> Repo.update!()

          :ok
        else
          {:error, "Unknown game mode #{inspect(game_mode)}"}
        end

      _ ->
        {:error, "Unknown player"}
    end
  rescue
    e ->
      Logger.warning(
        "Failed to fetch player info for #{player.display_name}: #{Exception.message(e)}"
      )

      {:error, "Failed to fetch"}
  end

  @doc """
  Fetches game mode for all players from TempleOSRS. Not updated automatically.
  """
  @spec refresh_game_modes() :: [{String.t(), :ok | {:error, String.t()}}]
  def refresh_game_modes() do
    players = Repo.all(Player)

    players
    |> Task.async_stream(&refresh_game_mode/1,
      max_concurrency: @fetch_concurrency,
      timeout: @fetch_timeout,
      on_timeout: :kill_task
    )
    |> Enum.zip_with(players, fn
      {:ok, result}, player -> {player.display_name, result}
      {:exit, _reason}, player -> {player.display_name, {:error, "Timed out"}}
    end)
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

defmodule DiscordBot.Bosses do
  use GenServer
  require Logger
  alias DiscordBot.TempleOsrs

  @bosses %{
    "Amoxliatl" => 0,
    "Araxxor" => 0,
    "Brutus" => 0,
    "Clue_all" => 0,
    "Clue_beginner" => 0,
    "Clue_easy" => 0,
    "Clue_medium" => 0,
    "Clue_hard" => 0,
    "Clue_elite" => 0,
    "Clue_master" => 0,
    "Doom of Mokhaiotl" => 0,
    "LMS" => 0,
    "Abyssal Sire" => 0,
    "Alchemical Hydra" => 0,
    "Barrows Chests" => 0,
    "Bryophyta" => 0,
    "Callisto" => 0,
    "Cerberus" => 0,
    "Chambers of Xeric" => 0,
    "Chambers of Xeric Challenge Mode" => 0,
    "Chaos Elemental" => 0,
    "Chaos Fanatic" => 0,
    "Colosseum Glory" => 0,
    "Commander Zilyana" => 0,
    "Corporeal Beast" => 0,
    "Crazy Archaeologist" => 0,
    "Dagannoth Prime" => 0,
    "Dagannoth Rex" => 0,
    "Dagannoth Supreme" => 0,
    "Deranged Archaeologist" => 0,
    "General Graardor" => 0,
    "Giant Mole" => 0,
    "Grotesque Guardians" => 0,
    "Hespori" => 0,
    "Hueycoatl" => 0,
    "Kalphite Queen" => 0,
    "King Black Dragon" => 0,
    "Kraken" => 0,
    "KreeArra" => 0,
    "Kril Tsutsaroth" => 0,
    "Lunar Chests" => 0,
    "Mad Angel" => 0,
    "Maggot King" => 0,
    "Mimic" => 0,
    "Obor" => 0,
    "Sarachnis" => 0,
    "Scorpia" => 0,
    "Scurrius" => 0,
    "Shellbane Gryphon" => 0,
    "Skotizo" => 0,
    "Sol Heredit" => 0,
    "The Gauntlet" => 0,
    "The Corrupted Gauntlet" => 0,
    "Theatre of Blood" => 0,
    "Thermonuclear Smoke Devil" => 0,
    "TzKal-Zuk" => 0,
    "TzTok-Jad" => 0,
    "Venenatis" => 0,
    "Vetion" => 0,
    "Vorkath" => 0,
    "Wintertodt" => 0,
    "Zalcano" => 0,
    "Zulrah" => 0,
    "The Nightmare" => 0,
    "Soul Wars Zeal" => 0,
    "Tempoross" => 0,
    "Theatre of Blood Challenge Mode" => 0,
    "Bounty Hunter Hunter" => 0,
    "Bounty Hunter Rogue" => 0,
    "Phosanis Nightmare" => 0,
    "Nex" => 0,
    "Rift" => 0,
    "PvP Arena" => 0,
    "Tombs of Amascut" => 0,
    "Tombs of Amascut Expert" => 0,
    "Phantom Muspah" => 0,
    "Artio" => 0,
    "Calvarion" => 0,
    "Spindel" => 0,
    "Duke Sucellus" => 0,
    "The Leviathan" => 0,
    "The Royal Titans" => 0,
    "The Whisperer" => 0,
    "Vardorvis" => 0,
    "Yama" => 0
  }
  @boss_renames %{
    "Clue_all" => "Clue (all)",
    "Clue_beginner" => "Clue (beginner)",
    "Clue_easy" => "Clue (easy)",
    "Clue_medium" => "Clue (medium)",
    "Clue_hard" => "Clue (hard)",
    "Clue_elite" => "Clue (elite)",
    "Clue_master" => "Clue (master)",
    "KreeArra" => "Kree'Arra",
    "Kril Tsutsaroth" => "K'ril Tsutsaroth",
    "Chambers of Xeric Challenge Mode" => "Chambers of Xeric (CM)",
    "Theatre of Blood Challenge Mode" => "Theatre of Blood (CM)",
    "The Leviathan" => "Leviathan",
    "The Whisperer" => "Whisperer"
  }
  @boss_aliases %{
    "cox" => "Chambers of Xeric",
    "sara" => "Commander Zilyana",
    "bandos" => "General Graardor",
    "arma" => "KreeArra",
    "zammy" => "Kril Tsutsaroth",
    "gg" => "Grotesque Guardians",
    "cg" => "The Corrupted Gauntlet",
    "tob" => "Theatre of Blood",
    "pumpalumpa" => "Phantom Muspah",
    "pm" => "Lunar Chests",
    "perilous moons" => "Lunar Chests",
    "lc" => "Lunar Chests",
    "toa" => "Tombs of Amascut",
    "huey" => "Hueycoatl",
    "amox" => "Amoxliatl",
    "colosseum" => "Sol Heredit",
    "delve" => "Doom of Mokhaiotl"
  }

  @boss_grouping [
    ["Chambers of Xeric", "Chambers of Xeric Challenge Mode"],
    ["Theatre of Blood", "Theatre of Blood Challenge Mode"],
    ["Tombs of Amascut", "Tombs of Amascut Expert"]
  ]

  @type player :: String.t()
  @type boss :: String.t()
  @type boss_map :: %{boss() => non_neg_integer()}
  @type table_record :: {player(), boss_map(), non_neg_integer()}

  @table :bosses
  @cache_ttl 120
  @fetch_concurrency 10
  @fetch_timeout 30_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # The GenServer only owns the ETS table; reads and writes happen in the caller's process
  # so that slow TempleOSRS requests don't serialize behind each other.
  @impl true
  def init(_state) do
    table = :ets.new(@table, [:named_table, :public, read_concurrency: true])
    {:ok, table}
  end

  @spec fetch_player_bosses(player()) :: {:ok, boss_map()} | {:error, String.t()}
  def fetch_player_bosses(player) do
    with {:ok, results} <- fetch_bosses(player, nil) do
      :ets.insert(@table, {player, results, System.monotonic_time(:second)})
      {:ok, results}
    end
  end

  @doc """
  Fetches historical boss data for `player` at `date`. Not cached.
  """
  @spec fetch_player_bosses_at(player(), DateTime.t()) :: {:ok, boss_map()} | {:error, String.t()}
  def fetch_player_bosses_at(player, date) do
    fetch_bosses(player, date)
  end

  defp fetch_bosses(player, date) do
    case TempleOsrs.fetch_player_stats(player, date) do
      %{body: %{"data" => data}} when is_map(data) ->
        {:ok, Map.take(data, Map.keys(@bosses))}

      _ ->
        {:error, "Unknown player"}
    end
  rescue
    e ->
      Logger.warning("Failed to fetch boss data for #{player}: #{Exception.message(e)}")
      {:error, "Failed to fetch"}
  end

  @spec lookup(player()) :: [table_record()]
  def lookup(player) do
    :ets.lookup(@table, player)
  end

  @spec boss_display_name(boss()) :: boss()
  def boss_display_name(name) do
    Map.get(@boss_renames, name, name)
  end

  @spec get_bosses :: [boss()]
  def get_bosses do
    Map.keys(@bosses)
  end

  @spec find_boss(String.t()) :: [boss()]
  def find_boss(input) do
    with nil <- @bosses[input] && input,
         input = String.trim(input) |> String.downcase(),
         nil <- @boss_aliases[input] do
      regex = Regex.compile!(input, "i")

      get_bosses()
      |> Stream.map(fn boss ->
        case Regex.run(regex, boss, return: :index) do
          nil -> nil
          [{idx, _}] -> {idx, boss}
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))
    else
      boss -> [boss]
    end
  end

  @spec get_player_bosses(player()) :: {:ok, boss_map()} | {:error, String.t()}
  def get_player_bosses(player) do
    case lookup(player) do
      [] ->
        Logger.debug("Fetching new boss data for #{player}")
        fetch_player_bosses(player)

      [{player, results, timestamp}] ->
        # If data is older than @cache_ttl, fetch new
        if timestamp < System.monotonic_time(:second) - @cache_ttl do
          Logger.debug("Fetching updated boss data for #{player}")
          fetch_player_bosses(player)
        else
          {:ok, results}
        end
    end
  end

  @doc """
  Gets boss data for all players, fetching uncached players concurrently.
  Results are in the same order as `players`.
  """
  @spec get_players_bosses([player()]) ::
          [{player(), {:ok, boss_map()} | {:error, String.t()}}]
  def get_players_bosses(players) do
    players
    |> Task.async_stream(&get_player_bosses/1,
      max_concurrency: @fetch_concurrency,
      timeout: @fetch_timeout,
      on_timeout: :kill_task
    )
    |> Enum.zip_with(players, fn
      {:ok, result}, player -> {player, result}
      {:exit, _reason}, player -> {player, {:error, "Timed out"}}
    end)
  end

  @spec get_group_bosses([player()]) ::
          {boss_map(), [{:ok, player(), boss_map()} | {:error, player(), String.t()}]}
  def get_group_bosses(players) do
    Enum.reduce(
      get_players_bosses(players),
      {@bosses, []},
      fn
        {player, {:ok, player_bosses}}, {totals, all_players} ->
          {
            Map.merge(totals, player_bosses, fn _key, total_c, player_c ->
              total_c + player_c
            end),
            [{:ok, player, player_bosses} | all_players]
          }

        {player, {:error, msg}}, {totals, all_players} ->
          {totals, [{:error, player, msg} | all_players]}
      end
    )
  end

  def get_related_bosses(boss) do
    case Enum.filter(@boss_grouping, fn group -> Enum.member?(group, boss) end) do
      [] -> [boss]
      [group] -> group
    end
  end
end

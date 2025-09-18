defmodule DiscordBot.Bosses do
  use GenServer
  require Logger
  alias DiscordBot.Errors.NoBossError
  alias DiscordBot.TempleOsrs

  @bosses %{
    "Amoxliatl" => 0,
    "Araxxor" => 0,
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
    "Mimic" => 0,
    "Obor" => 0,
    "Sarachnis" => 0,
    "Scorpia" => 0,
    "Scurrius" => 0,
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

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    table = :ets.new(:bosses, [])
    {:ok, table}
  end

  @impl true
  def handle_call({:lookup, player}, _from, table) do
    {:reply, :ets.lookup(table, player), table}
  end

  def handle_call({:fetch_player_bosses, player}, _from, table) do
    res = TempleOsrs.fetch_player_stats(player)

    if is_nil(res.body["data"]) do
      {:reply, {:error, "Unknown player"}, table}
    else
      results = Map.take(res.body["data"], Map.keys(@bosses))
      :ets.insert(table, {player, results, System.monotonic_time(:second)})
      {:reply, {:ok, results}, table}
    end
  end

  @spec fetch_player_bosses(player()) :: {:ok, boss_map()} | {:error, String.t()}
  def fetch_player_bosses(player) do
    GenServer.call(__MODULE__, {:fetch_player_bosses, player})
  end

  @spec lookup(player()) :: [table_record()]
  def lookup(player) do
    GenServer.call(__MODULE__, {:lookup, player})
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
        # If data is older than 120s, fetch new
        if timestamp < System.monotonic_time(:second) - 120 do
          Logger.debug("Fetching updated boss data for #{player}")
          fetch_player_bosses(player)
        else
          {:ok, results}
        end
    end
  end

  @spec get_group_bosses([player()]) ::
          {boss_map(), [{:ok, player(), boss_map()} | {:error, player(), String.t()}]}
  def get_group_bosses(players) do
    Enum.reduce(
      players,
      {@bosses, []},
      fn player, {totals, all_players} ->
        case get_player_bosses(player) do
          {:ok, player_bosses} ->
            {
              Map.merge(totals, player_bosses, fn _key, total_c, player_c ->
                total_c + player_c
              end),
              [{:ok, player, player_bosses} | all_players]
            }

          {:error, msg} ->
            {totals, [{:error, player, msg} | all_players]}
        end
      end
    )
  end

  @spec get_group_boss([player()], boss()) ::
          {non_neg_integer(),
           [{:ok, player(), non_neg_integer()} | {:error, player(), String.t()}]}
  def get_group_boss(players, boss) do
    if is_nil(@bosses[boss]) do
      raise NoBossError
    end

    Enum.reduce(
      players,
      {0, []},
      fn player, {total_c, all_players} ->
        case get_player_bosses(player) do
          {:ok, player_bosses} ->
            boss_count = player_bosses[boss]
            {total_c + boss_count, [{:ok, player, boss_count} | all_players]}

          {:error, msg} ->
            {total_c, [{:error, player, msg} | all_players]}
        end
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

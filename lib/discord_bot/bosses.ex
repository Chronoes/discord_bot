defmodule DiscordBot.Bosses do
  use GenServer
  require Logger
  alias DiscordBot.Errors.NoBossError
  alias DiscordBot.State

  @bosses %{
    "Clue_all" => 0,
    "Clue_beginner" => 0,
    "Clue_easy" => 0,
    "Clue_medium" => 0,
    "Clue_hard" => 0,
    "Clue_elite" => 0,
    "Clue_master" => 0,
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
    "Kalphite Queen" => 0,
    "King Black Dragon" => 0,
    "Kraken" => 0,
    "KreeArra" => 0,
    "Kril Tsutsaroth" => 0,
    "Mimic" => 0,
    "Obor" => 0,
    "Sarachnis" => 0,
    "Scorpia" => 0,
    "Skotizo" => 0,
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
    "Spindel" => 0
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
    "Theatre of Blood Challenge Mode" => "Theatre of Blood (CM)"
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
    "toa" => "Tombs of Amascut"
  }

  @type boss :: String.t()
  @type boss_map :: %{boss() => non_neg_integer()}
  @type table_record :: {State.player(), boss_map(), non_neg_integer()}

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
    res =
      Req.get!(
        "https://templeosrs.com/api/player_stats.php?player=#{URI.encode(player)}&bosses=1"
      )

    results = Map.take(res.body["data"], Map.keys(@bosses))
    :ets.insert(table, {player, results, System.monotonic_time(:second)})
    {:reply, results, table}
  end

  @spec fetch_player_bosses(State.player()) :: boss_map()
  def fetch_player_bosses(player) do
    GenServer.call(__MODULE__, {:fetch_player_bosses, player})
  end

  @spec lookup(State.player()) :: [table_record()]
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

  @spec get_player_bosses(State.player()) :: boss_map()
  def get_player_bosses(player) do
    case lookup(player) do
      [] ->
        Logger.debug("Fetching new boss data for #{player}")
        fetch_player_bosses(player)

      [{player, results, timestamp}] ->
        # If data is older than 10min, fetch new
        if timestamp < System.monotonic_time(:second) - 600 do
          Logger.debug("Fetching updated boss data for #{player}")
          fetch_player_bosses(player)
        else
          results
        end
    end
  end

  @spec get_group_bosses([State.player()]) :: {boss_map(), [{State.player(), boss_map()}]}
  def get_group_bosses(players) do
    Enum.reduce(
      players,
      {@bosses, []},
      fn player, {totals, all_players} ->
        player_bosses = get_player_bosses(player)

        {
          Map.merge(totals, player_bosses, fn _key, total_c, player_c -> total_c + player_c end),
          [{player, player_bosses} | all_players]
        }
      end
    )
  end

  @spec get_group_boss([State.player()], boss()) ::
          {{boss(), non_neg_integer()}, [{State.player(), non_neg_integer()}]}
  def get_group_boss(players, boss) do
    if is_nil(@bosses[boss]) do
      raise NoBossError
    end

    Enum.reduce(
      players,
      {{boss, 0}, []},
      fn player, {{boss, total_c}, all_players} ->
        player_bosses = get_player_bosses(player)
        boss_count = player_bosses[boss]

        {
          {boss, total_c + boss_count},
          [{player, boss_count} | all_players]
        }
      end
    )
  end
end

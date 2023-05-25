defmodule DiscordBot.Bosses do
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
    "Chambers of Xeric Challenge Mode" => "Chambers of Xeric (CM)",
    "Theatre of Blood Challenge Mode" => "Theatre of Blood (CM)"
  }

  def boss_display_name(name) do
    Map.get(@boss_renames, name, name)
  end

  def get_bosses do
    Map.keys(@bosses)
  end

  def fetch_player_bosses(player) do
    # TODO: Figure out some sort of caching to not spam the external endpoint
    res =
      Req.get!(
        "https://templeosrs.com/api/player_stats.php?player=#{URI.encode(player)}&bosses=1"
      )

    Map.take(res.body["data"], Map.keys(@bosses))
  end

  def fetch_group_bosses(players) do
    Enum.reduce(
      players,
      {@bosses, %{}},
      fn player, {totals, all_players} ->
        player_bosses = fetch_player_bosses(player)

        {
          Map.merge(totals, player_bosses, fn _key, total_c, player_c -> total_c + player_c end),
          Map.put_new(all_players, player, player_bosses)
        }
      end
    )
  end
end

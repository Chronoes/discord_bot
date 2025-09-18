existing_bosses = DiscordBot.Bosses.get_bosses()

random_player =
  DiscordBot.Players.get_all_players()
  |> Enum.random()

unrelated_fields = ["Crafting_rank", "Fletching_ehp", "Tombs of Amascut Expert_ehb",
 "Grotesque Guardians_ehb", "Callisto_ehb", "Attack_ehp",
 "The Corrupted Gauntlet_ehb", "Ranged_level", "Farming_level", "Magic_rank",
 "Construction_ehp", "Scorpia_ehb", "Hunter_level",
 "Attack_rank", "Farming", "TzKal-Zuk_ehb", "Lunar Chests_ehb",
 "Phosanis Nightmare_ehb", "Construction_level", "Mining_ehp",
 "Runecraft_rank", "Woodcutting_rank", "Crafting_level", "Defence",
 "Duke Sucellus_ehb", "Smithing_rank", "Herblore_level", "Attack_level",
 "Sol Heredit_ehb", "Spindel_ehb", "Cerberus_ehb", "Attack", "Fletching",
 "Overall_rank", "KreeArra_ehb", "Herblore", "Thermonuclear Smoke Devil_ehb",
 "Uim_ehb", "Alchemical Hydra_ehb", "TzTok-Jad_ehb", "Woodcutting_level",
 "Agility_level", "Theatre of Blood_ehb", "The Whisperer_ehb", "Ranged_rank",
 "Im_ehb", "Theatre of Blood Challenge Mode_ehb", "The Gauntlet_ehb", "Ehp",
 "Smithing_level", "Smithing", "Tombs of Amascut_ehb", "The Royal Titans_ehb",
 "Fishing_level", "Mining_level", "Im_ehp", "Ehp_rank", "Strength_ehp",
 "Farming_rank", "Smithing_ehp", "Hueycoatl_ehb", "Nex_ehb", "Herblore_ehp",
 "1def_ehb", "Dagannoth Rex_ehb", "Crafting_ehp", "Ranged", "Fletching_rank",
 "Doom of Mokhaiotl_ehb", "Uim_ehp", "Defence_rank", "Defence_level",
 "Kraken_ehb", "Agility_ehp", "Ehb", "Prayer_level", "Fishing_ehp",
 "Thieving_rank", "Overall", "Woodcutting_ehp", "Ranged_ehp", "Firemaking_rank",
 "Phantom Muspah_ehb", "Hitpoints_rank", "Gim_ehp", "Construction_rank",
 "Chambers of Xeric_ehb", "Prayer_rank", "info", "Araxxor_ehb", "Crafting",
 "Firemaking_ehp", "F2p_ehp", "Cooking_level", "Agility",
 "Amoxliatl_ehb", "Hunter", "Hitpoints_level", "Cooking", "Runecraft_ehp",
 "Yama_ehb", "Chaos Fanatic_ehb", "Zulrah_ehb", "Runecraft_level",
 "Chaos Elemental_ehb", "Defence_ehp", "Prayer_ehp", "Overall_ehp",
 "Firemaking", "Artio_ehb", "Slayer_rank", "Strength_level", "Giant Mole_ehb",
 "Runecraft", "Chambers of Xeric Challenge Mode_ehb", "Fishing",
 "Dagannoth Prime_ehb", "Skotizo_ehb", "King Black Dragon_ehb", "Hunter_rank",
 "Fletching_level", "Sarachnis_ehb", "Vetion_ehb",
 "Vorkath_ehb", "Slayer", "Hitpoints", "Calvarion_ehb", "Firemaking_level",
 "The Nightmare_ehb", "Woodcutting", "Corporeal Beast_ehb", "Magic_level",
 "1def_ehp", "Lvl3_ehp", "Herblore_rank", "The Leviathan_ehb", "Mining_rank",
 "Construction", "Vardorvis_ehb", "Venenatis_ehb", "Magic_ehp",
 "Kalphite Queen_ehb", "Strength", "Slayer_ehp", "Agility_rank", "Fishing_rank",
 "Collections", "Overall_level", "Thieving_ehp", "Magic", "Kril Tsutsaroth_ehb",
 "date", "Commander Zilyana_ehb", "Prayer", "Thieving", "Abyssal Sire_ehb",
 "Slayer_level", "Hitpoints_ehp", "Cooking_rank", "Cooking_ehp",
 "Dagannoth Supreme_ehb", "Thieving_level", "Mining", "General Graardor_ehb",
 "Strength_rank", "Farming_ehp", "Scurrius_ehb", "Hunter_ehp"]

templeosrs_data = DiscordBot.TempleOsrs.fetch_player_stats(random_player.name).body["data"]

updated_bosses =
  templeosrs_data
  |> Map.keys()
  |> Enum.reject(fn key -> Enum.member?(unrelated_fields, key) end)
  |> Enum.reject(fn key -> Enum.member?(existing_bosses, key) end)

IO.inspect(updated_bosses, label: "New Fields Found", limit: :infinity)

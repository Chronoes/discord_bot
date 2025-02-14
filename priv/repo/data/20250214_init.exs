alias DiscordBot.Players
alias DiscordBot.Guilds
alias DiscordBot.Repo

Players.create_player("HardJongMunn", nil)
Players.create_player("BraveGobl1n", nil)
Players.create_player("MrSeedman", nil)
Players.create_player("Caspyy", nil)
Players.create_player("palmre", nil)
Players.create_player("iMoosey", nil)

Players.create_player("janes1", "ainid")
Players.create_player("Enchseedman", "ainid")
Players.create_player("Caspyyyy", "ainid")
Players.create_player("Br4vechicken", "ainid")
Players.create_player("Gim Jongmunn", "ainid")

Repo.insert!(
  %Guilds.Guild{
    guild_id: 199951013061328896,
    name: "pela",
    commands: [:kc, :deaths],
    channels: [
      %Guilds.Channel{
        channel_id: 1111266719370055741,
        name: "#bot-test",
        actions: [:competition, :deaths]
      }
    ]
  }
)
Repo.insert!(
  %Guilds.Guild{
    guild_id: 895259980515672064,
    name: "GIM ainid",
    commands: [:kc, :deaths],
    channels: [
      %Guilds.Channel{
        channel_id: 1282379303203635272,
        name: "#oof",
        actions: [:deaths]
      }
    ]
  }
)
Repo.insert!(
  %Guilds.Guild{
    guild_id: 290569530319831050,
    name: "Ramrod",
    commands: [],
    channels: [
      %Guilds.Channel{
        channel_id: 290573754768293888,
        name: "#skill-weeks",
        actions: [:competition]
      }
    ]
  }
)

alias DiscordBot.Guilds
alias DiscordBot.Repo
guild = Guilds.get_guild(895259980515672064)

Repo.insert!(
  %Guilds.Channel{
    channel_id: 1077529175465930822,
    name: "#events",
    actions: [:deaths],
    guild: guild
  }
)

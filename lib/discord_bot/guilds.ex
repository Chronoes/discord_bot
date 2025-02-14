defmodule DiscordBot.Guilds do
  alias Nostrum.Struct.Guild, as: NostrumGuild
  alias Nostrum.Struct.Channel, as: NostrumChannel
  alias DiscordBot.Repo
  alias DiscordBot.Guilds.{Guild, Channel}

  @spec get_all_guilds() :: [%Guild{}]
  def get_all_guilds() do
    Repo.all(Guild) |> Repo.preload(:channels)
  end

  @spec get_guild(NostrumGuild.id()) :: %Guild{} | nil
  def get_guild(guild_id) do
    Repo.get_by(Guild, guild_id: guild_id)
  end

  @spec get_guild_channel(NostrumChannel.id()) :: %Channel{} | nil
  def get_guild_channel(channel_id) do
    Channel
    |> Repo.get_by(channel_id: channel_id)
  end
end

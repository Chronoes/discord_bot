defmodule DiscordBot.Guilds.Guild do
  use Ecto.Schema
  import Ecto.Changeset
  alias DiscordBot.Guilds.Channel
  alias DiscordBot.Repo.Type.Snowflake

  schema "guilds" do
    timestamps()
    field(:guild_id, Snowflake)
    field(:name, :string)
    field(:commands, {:array, Ecto.Enum}, values: [:kc, :deaths])
    has_many(:channels, Channel)
  end

  def changeset(%__MODULE__{} = guild, attrs) do
    guild
    |> cast(attrs, [:guild_id, :name])
    |> validate_required([:guild_id, :name])
  end
end

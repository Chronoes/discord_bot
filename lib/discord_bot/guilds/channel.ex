defmodule DiscordBot.Guilds.Channel do
  use Ecto.Schema
  import Ecto.Changeset
  alias DiscordBot.Guilds.Guild
  alias DiscordBot.Repo.Type.Snowflake

  schema "channels" do
    timestamps()
    field(:channel_id, Snowflake)
    field(:name, :string)
    field(:actions, {:array, Ecto.Enum}, values: [:competition, :deaths])
    belongs_to(:guild, Guild)
  end

  def changeset(%__MODULE__{} = channel, attrs) do
    channel
    |> cast(attrs, [:channel_id, :name])
    |> validate_required([:channel_id, :name])
  end
end

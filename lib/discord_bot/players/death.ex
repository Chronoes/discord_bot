defmodule DiscordBot.Players.Death do
  use Ecto.Schema
  import Ecto.Changeset
  alias DiscordBot.Repo.Type.Snowflake

  schema "deaths" do
    belongs_to(:player, DiscordBot.Players.Player)
    field(:timestamp, :utc_datetime)
    field(:message_id, Snowflake)
    field(:is_pk, :boolean, default: false)
  end

  def changeset(%__MODULE__{} = death, attrs) do
    {player, rest} = Map.pop(attrs, :player)

    death
    |> cast(rest, [:timestamp, :message_id, :is_pk])
    |> put_change(:player, player)
    |> validate_required([:player, :timestamp, :message_id])
  end
end

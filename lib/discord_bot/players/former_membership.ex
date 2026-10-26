defmodule DiscordBot.Players.FormerMembership do
  use Ecto.Schema
  import Ecto.Changeset

  # Boss KC of the player frozen at the time they left the group
  schema "former_memberships" do
    timestamps()
    belongs_to(:player, DiscordBot.Players.Player)
    field(:group, :string)
    field(:bosses, :map)
    field(:left_at, :utc_datetime)
  end

  def changeset(%__MODULE__{} = membership, attrs) do
    membership
    |> cast(attrs, [:player_id, :group, :bosses, :left_at])
    |> validate_required([:player_id, :group, :bosses, :left_at])
  end
end

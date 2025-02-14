defmodule DiscordBot.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field(:name, :string)
    field(:display_name, :string)
    field(:group, :string)
    has_many(:deaths, DiscordBot.Players.Death)
  end

  def changeset(%__MODULE__{} = player, attrs) do
    player
    |> cast(attrs, [:name, :display_name, :group])
    |> validate_required([:name, :display_name])
    |> unique_constraint(:name)
  end
end

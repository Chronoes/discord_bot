defmodule DiscordBot.Competition.CompetitionPlayer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "competition_players" do
    timestamps()
    field(:name, :string)
    field(:competition_uuid, :binary)
    field(:name_changed, :boolean, default: false)
    field(:notified, :boolean, default: false)
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :competition_uuid, :name_changed, :notified])
    |> validate_required([:name, :competition_uuid])
  end
end

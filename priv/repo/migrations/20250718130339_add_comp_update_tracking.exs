defmodule DiscordBot.Repo.Migrations.AddCompUpdateTracking do
  use Ecto.Migration

  def change do
    create table(:competition_players) do
      timestamps()
      add :name, :string
      add :competition_uuid, :binary
      add :name_changed, :boolean, default: false
      add :notified, :boolean, default: false
    end
  end
end

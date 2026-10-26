defmodule DiscordBot.Repo.Migrations.AddFormerMembershipsAndGameMode do
  use Ecto.Migration

  def change do
    create table(:former_memberships) do
      timestamps()
      add :player_id, references(:players, on_delete: :delete_all)
      add :group, :string
      add :bosses, :map
      add :left_at, :utc_datetime
    end

    create index(:former_memberships, [:player_id])

    alter table(:players) do
      add :game_mode, :integer
      add :gim_mode, :integer
    end
  end
end

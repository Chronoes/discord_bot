defmodule DiscordBot.Repo.Migrations.InitDatabase do
  use Ecto.Migration

  def change do
    create table(:guilds) do
      timestamps()
      add :guild_id, :string
      add :name, :string
      add :commands, {:array, :string}
    end

    create unique_index(:guilds, [:guild_id])

    create table(:channels) do
      timestamps()
      add :channel_id, :string
      add :name, :string
      add :actions, {:array, :string}
      add :guild_id, references(:guilds, on_delete: :delete_all)
    end

    create unique_index(:channels, [:channel_id])

    create table(:players) do
      add :name, :string
      add :display_name, :string
      add :group, :string
    end

    create unique_index(:players, [:name])

    create table(:deaths) do
      add :player_id, references(:players, on_delete: :delete_all)
      add :timestamp, :utc_datetime
      add :message_id, :string
    end

    create index(:deaths, [:player_id])
    create index(:deaths, [:message_id])
  end
end

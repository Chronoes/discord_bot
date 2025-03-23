defmodule DiscordBot.Repo.Migrations.AddIsPkColumn do
  use Ecto.Migration

  def change do
    alter table(:deaths) do
      add :is_pk, :boolean, default: false
    end
  end
end

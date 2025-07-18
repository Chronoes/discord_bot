defmodule DiscordBot.Competition do
  import Ecto.Query
  alias DiscordBot.Repo
  alias DiscordBot.Competition.CompetitionPlayer

  @spec delete_players_if_resolved(binary()) :: {:ok, integer} | {:error, term}
  def delete_players_if_resolved(competition_uuid) do
    from(p in CompetitionPlayer, where: p.competition_uuid != ^competition_uuid)
    |> Repo.delete_all()
  end

  @spec add_player(String.t(), binary(), keyword()) ::
          {:ok, CompetitionPlayer.t()} | {:error, Ecto.Changeset.t()}
  def add_player(player_name, competition_uuid, values) do
    name_changed = Keyword.get(values, :name_changed, false)
    other_issue = Keyword.get(values, :other_issue, false)

    case Repo.get_by(CompetitionPlayer, name: player_name) do
      nil ->
        %CompetitionPlayer{}

      player ->
        player
    end
    |> CompetitionPlayer.changeset(%{
      name: player_name,
      competition_uuid: competition_uuid,
      name_changed: name_changed,
      other_issue: other_issue
    })
    |> Repo.insert_or_update()
  end

  @spec get_players() :: [CompetitionPlayer.t()]
  def get_players() do
    Repo.all(CompetitionPlayer)
  end

  def notify_players(players) do
    players
    |> Enum.each(fn player ->
      CompetitionPlayer.changeset(player, %{notified: true})
      |> Repo.update()
    end)
  end
end

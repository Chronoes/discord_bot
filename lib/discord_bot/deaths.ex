defmodule DiscordBot.Deaths do
  require Logger
  import Ecto.Query
  alias Nostrum.Snowflake
  alias DiscordBot.Repo
  alias DiscordBot.Players

  @spec add_deaths_from_message(Nostrum.Struct.Message.t()) :: :noop | :oof
  @spec add_deaths_from_message(Nostrum.Struct.Message.t(), boolean()) :: :noop | :oof
  def add_deaths_from_message(
        %Nostrum.Struct.Message{embeds: embeds} = message,
        update_in_place \\ false
      ) do
    death_qry = from(d in Players.Death, where: d.message_id == ^message.id)

    if Repo.exists?(death_qry) do
      if update_in_place do
        death_embeds = only_death_embeds(embeds)

        death_qry
        |> preload([:player])
        |> Repo.all()
        |> Enum.flat_map(fn death ->
          death_embeds |> Enum.map(&parse_death_embed(death, message, &1))
        end)
        |> Enum.each(&Repo.update!/1)
      end

      :noop
    else
      deaths =
        embeds
        |> only_death_embeds()
        |> Enum.map(&parse_death_embed(%Players.Death{}, message, &1))

      if Enum.empty?(deaths) do
        :noop
      else
        Enum.each(deaths, &Repo.insert!/1)
        :oof
      end
    end
  end

  defp only_death_embeds(embeds) do
    Enum.filter(embeds, fn %Nostrum.Struct.Embed{title: title} ->
      title === "Player Death"
    end)
  end

  defp parse_death_embed(
         %Players.Death{} = death,
         %Nostrum.Struct.Message{id: id, timestamp: timestamp},
         %Nostrum.Struct.Embed{author: author, description: description}
       ) do
    player = Players.get_or_create(author.name)

    death
    |> Players.Death.changeset(%{
      player: player,
      timestamp: timestamp,
      message_id: id,
      is_pk: String.contains?(description, "has just been PKed")
    })
  end

  @spec remove_deaths([Snowflake.t()]) :: :ok
  def remove_deaths(msg_ids) do
    from(d in Players.Death, where: d.message_id in ^msg_ids)
    |> Repo.delete_all()
  end

  @spec fetch_all_deaths(Nostrum.Struct.Channel.id()) ::
          integer() | :error
  @spec fetch_all_deaths(Nostrum.Struct.Channel.id(), boolean()) ::
          integer() | :error
  def fetch_all_deaths(channel_id, update_in_place \\ false) do
    case fetch_all_deaths(channel_id, update_in_place, {}) do
      :error ->
        :error

      count ->
        Logger.info("Parsed #{count} deaths from channel #{channel_id}")
        count
    end
  end

  defp fetch_all_deaths(channel_id, update_in_place, locator) do
    case Nostrum.Api.Channel.messages(channel_id, 20, locator) do
      {:ok, messages} ->
        deaths =
          messages
          |> Enum.map(&add_deaths_from_message(&1, update_in_place))
          |> Enum.filter(&(&1 === :oof))

        last_msg = List.last(messages)

        if last_msg do
          length(deaths) + fetch_all_deaths(channel_id, update_in_place, {:before, last_msg.id})
        else
          length(deaths)
        end

      {:error, err} ->
        Logger.error(
          "Channel #{channel_id} received HTTP #{err.status_code}, Discord error #{err.response.code}: #{err.response.message}"
        )

        :error
    end
  end

  @spec report() :: String.t()
  def report() do
    players = Players.get_death_count_by_player()
    list_content = get_players_deaths_list(players)

    "**Deaths:** PvM [PK]\n```\n#{list_content}\n```"
  end

  @spec report(Date.t()) :: String.t()
  def report(date) do
    players_at_date = Players.get_death_count_by_player(date)
    players = Players.get_death_count_by_player()

    list_content = get_players_deaths_list(players, players_at_date)

    "**Deaths since #{Date.to_string(date)}:** PvM [PK]\n```\n#{list_content}\n```"
  end

  defp left_len_fn_of_players(players) do
    DiscordBot.StringUtil.left_padding_fn(
      players
      |> Enum.map(fn {player, _} -> player.display_name end)
    )
  end

  defp get_players_deaths_list(players) do
    left_len = left_len_fn_of_players(players)

    players
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.map(fn {player, {pvm_count, pk_count}} ->
      text = "#{left_len.(player.display_name)}: #{String.pad_trailing(to_string(pvm_count), 4)}"

      if pk_count > 0 do
        "#{text} [#{pk_count}]"
      else
        text
      end
    end)
    |> Enum.join("\n")
  end

  defp get_players_deaths_list(players, players_prev) do
    left_len = left_len_fn_of_players(players)

    players
    |> Enum.map(fn {player, {pvm_count, pk_count} = counts} ->
      case Enum.find(players_prev, fn {p, _} -> p.id == player.id end) do
        nil ->
          {player, counts, {pvm_count, pk_count}}

        {p, {prev_pvm_count, prev_pk_count}} ->
          {p, counts, {pvm_count - prev_pvm_count, pk_count - prev_pk_count}}
      end
    end)
    |> Enum.sort_by(fn {_, _, {diff_pvm, _}} -> diff_pvm end, :desc)
    |> Enum.map(fn {player, {pvm_count, pk_count}, {diff_pvm, diff_pk}} ->
      text =
        "#{left_len.(player.display_name)}: +#{String.pad_trailing(to_string(diff_pvm), 3)} #{String.pad_trailing("(#{pvm_count})", 6)}"

      if pk_count > 0 do
        if diff_pk > 0 do
          "#{text} [+#{String.pad_trailing(to_string(diff_pk), 3)} (#{pk_count})]"
        else
          "#{text} [#{pk_count}]"
        end
      else
        text
      end
    end)
    |> Enum.join("\n")
  end
end

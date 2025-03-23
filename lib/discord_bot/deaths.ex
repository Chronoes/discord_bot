defmodule DiscordBot.Deaths do
  require Logger
  require Ecto.Query
  alias DiscordBot.Repo
  alias DiscordBot.Players

  @spec add_deaths_from_message(Nostrum.Struct.Message.t()) :: :noop | :oof
  @spec add_deaths_from_message(Nostrum.Struct.Message.t(), boolean()) :: :noop | :oof
  def add_deaths_from_message(
        %Nostrum.Struct.Message{embeds: embeds} = message,
        update_in_place \\ false
      ) do
    death_qry = Ecto.Query.from(d in Players.Death, where: d.message_id == ^message.id)

    if Repo.exists?(death_qry) do
      if update_in_place do
        death_embeds = only_death_embeds(embeds)

        death_qry
        |> Ecto.Query.preload([:player])
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
end

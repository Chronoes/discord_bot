defmodule DiscordBot.Deaths do
  require Logger
  require Ecto.Query
  alias DiscordBot.Repo
  alias DiscordBot.Players

  @spec parse_deaths_from_message(Nostrum.Struct.Message.t()) :: :noop | :oof
  def parse_deaths_from_message(%Nostrum.Struct.Message{embeds: embeds} = message) do
    deaths =
      embeds
      |> Enum.filter(fn %Nostrum.Struct.Embed{title: title} ->
        title === "Player Death"
      end)
      |> Enum.map(&parse_death_embed(message, &1))

    if Enum.empty?(deaths) do
      :noop
    else
      Enum.each(deaths, &Repo.insert!(&1))
      :oof
    end
  end

  defp parse_death_embed(
         %Nostrum.Struct.Message{id: id, timestamp: timestamp},
         %Nostrum.Struct.Embed{author: author}
       ) do
    player = Players.get_or_create(author.name)

    %Players.Death{}
    |> Players.Death.changeset(%{
      player: player,
      timestamp: timestamp,
      message_id: id
    })
  end

  @spec fetch_all_deaths(Nostrum.Struct.Channel.id()) :: integer() | :error
  def fetch_all_deaths(channel_id) do
    case fetch_all_deaths(channel_id, {}) do
      :error ->
        :error

      count ->
        Logger.info("Parsed #{count} deaths from channel #{channel_id}")
        count
    end
  end

  defp fetch_all_deaths(channel_id, locator) do
    case Nostrum.Api.Channel.messages(channel_id, 20, locator) do
      {:ok, messages} ->
        deaths =
          messages
          |> Enum.reject(fn message ->
            Ecto.Query.from(d in Players.Death, where: d.message_id == ^message.id)
            |> Repo.exists?()
          end)
          |> Enum.map(&parse_deaths_from_message/1)

        last_msg = List.last(messages)

        if last_msg do
          length(deaths) + fetch_all_deaths(channel_id, {:before, last_msg.id})
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

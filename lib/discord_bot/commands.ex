defmodule DiscordBot.Commands do
  alias Nostrum.Constants.ApplicationCommandOptionType
  alias Nostrum.Struct.Interaction
  alias DiscordBot.Guilds
  alias DiscordBot.Players
  alias DiscordBot.Deaths
  alias DiscordBot.Errors.NoBossError

  # https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-interaction-callback-type
  @message 4
  @autocomplete_result 8

  def create_commands(guild_id) do
    guild = Guilds.get_guild(guild_id)

    if guild do
      init_commands(guild)
    end
  end

  defp init_commands(%Guilds.Guild{} = guild) do
    if Enum.member?(guild.commands, :kc) do
      command = %{
        name: "kc",
        description: "list boss KC for GIM",
        options: [
          %{
            name: "name",
            description: "Name of boss",
            type: ApplicationCommandOptionType.string(),
            required: true,
            autocomplete: true
          }
        ]
      }

      Nostrum.Api.ApplicationCommand.create_guild_command(guild.guild_id, command)
    end

    if Enum.member?(guild.commands, :deaths) do
      command = %{
        name: "oof",
        description: "list deaths recorded in channel",
        options: [
          %{
            name: "date",
            description: "Date to compare with (YYYY-MM-DD)",
            type: ApplicationCommandOptionType.string(),
            required: false
          }
        ]
      }

      Nostrum.Api.ApplicationCommand.create_guild_command(guild.guild_id, command)
    end
  end

  @doc """
  Returns either an immediate interaction response, or `{:deferred, build_data}` for slow commands.
  For the latter, the caller should defer the response and edit it with `build_data.()` afterwards.
  """
  @spec handle_interaction(Interaction.t()) :: map() | {:deferred, (-> map())}
  def handle_interaction(%Interaction{type: 4, data: %{name: "kc"}} = interaction) do
    %Interaction{data: %{options: options}} = interaction
    %{value: value} = Enum.find(options, fn opt -> opt.name === "name" end)

    choices =
      case value do
        "" ->
          Enum.shuffle(DiscordBot.Bosses.get_bosses())

        value ->
          DiscordBot.Bosses.find_boss(value)
      end
      |> Enum.take(25)
      |> Enum.map(fn boss ->
        %{name: DiscordBot.Bosses.boss_display_name(boss), value: boss}
      end)

    %{
      type: @autocomplete_result,
      data: %{choices: choices}
    }
  end

  def handle_interaction(%Interaction{data: %{name: "kc", options: options}} = _interaction) do
    %{value: value} = Enum.find(options, fn opt -> opt.name === "name" end)

    boss =
      case DiscordBot.Bosses.find_boss(value) do
        [] -> raise NoBossError
        [boss | _bosses] -> boss
      end

    {:deferred, fn -> %{content: get_kc_content(boss)} end}
  rescue
    e in NoBossError ->
      %{
        type: @message,
        data: %{
          content: "**#{e.message}**"
        }
      }
  end

  def handle_interaction(%Interaction{data: %{name: "oof", options: options}} = _interaction) do
    case Enum.find(options || [], fn opt -> opt.name === "date" end) do
      nil ->
        %{type: @message, data: %{content: Deaths.report()}}

      %{value: value} ->
        case Date.from_iso8601(value) do
          {:ok, date} ->
            %{type: @message, data: %{content: Deaths.report(date)}}

          {:error, _} ->
            content = Deaths.report()

            %{
              type: @message,
              data: %{content: "**Invalid date format. Use YYYY-MM-DD.**\n\n#{content}"}
            }
        end
    end
  end

  def handle_interaction(_) do
    %{type: @message, data: %{content: "N/A"}}
  end

  defp get_kc_content(boss) do
    players = Players.get_all_players()

    # Fetch all uncached players concurrently up front, so that groups and related bosses
    # below are served from cache instead of fetching group by group
    players
    |> Enum.map(& &1.display_name)
    |> DiscordBot.Bosses.get_players_bosses()

    DiscordBot.Bosses.get_related_bosses(boss)
    |> Enum.map(&get_boss_message_content(&1, players))
    |> Enum.join("\n")
  end

  defp get_boss_message_content(boss, players) do
    grouped_players =
      players
      |> Enum.group_by(& &1.group, & &1.display_name)
      |> Enum.map(fn {group, players} ->
        {total_count, player_counts} = DiscordBot.Bosses.get_group_boss(players, boss)
        {total_count, player_counts, group}
      end)

    total = Enum.map(grouped_players, &elem(&1, 0)) |> Enum.sum()
    boss_name = DiscordBot.Bosses.boss_display_name(boss)

    if total > 0 do
      player_totals =
        grouped_players
        |> Enum.flat_map(fn {_total_count, player_counts, group} ->
          player_counts
          |> Enum.filter(fn
            {:ok, _player, count} -> count > 0
            {:error, _player, _msg} -> true
          end)
          |> Enum.map(fn
            {:ok, player, count} ->
              if is_nil(group) do
                {player, count}
              else
                {"[#{group}] #{player}", count}
              end

            {:error, player, msg} ->
              {player, msg}
          end)
        end)
        |> Enum.sort_by(
          fn
            {_player, sortable} when is_integer(sortable) -> sortable
            _ -> 0
          end,
          :desc
        )

      left_len = DiscordBot.StringUtil.left_padding_fn(player_totals |> Enum.map(&elem(&1, 0)))

      content =
        player_totals
        |> Enum.map(fn {player, count} ->
          "#{left_len.(player)}: #{count}"
        end)
        |> Enum.join("\n")

      boss_totals =
        grouped_players
        |> Enum.reject(fn {_, _, group} -> is_nil(group) end)
        |> Enum.map(fn {count, _, group} -> "[#{group}]: #{count}" end)

      group_boss_header =
        if length(boss_totals) > 0 do
          "\n#{Enum.join(boss_totals, "\n")}"
        else
          ""
        end

      "**#{boss_name}: #{total}**#{group_boss_header}\n```\n#{content}\n```"
    else
      "**#{boss_name}: #{total}**"
    end
  end
end

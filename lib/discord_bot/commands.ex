defmodule DiscordBot.Commands do
  alias Nostrum.Constants.ApplicationCommandOptionType
  alias Nostrum.Struct.Interaction
  alias DiscordBot.Guilds
  alias DiscordBot.Players
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
        options: []
      }

      Nostrum.Api.ApplicationCommand.create_guild_command(guild.guild_id, command)
    end
  end

  @spec handle_interaction(Interaction.t()) :: map()
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

  def handle_interaction(%Interaction{data: %{name: "kc"}} = interaction) do
    %Interaction{data: %{options: options}} = interaction
    %{value: value} = Enum.find(options, fn opt -> opt.name === "name" end)

    boss =
      case DiscordBot.Bosses.find_boss(value) do
        [] -> raise NoBossError
        [boss | _bosses] -> boss
      end

    content =
      DiscordBot.Bosses.get_related_bosses(boss)
      |> Enum.map(&get_boss_message_content/1)
      |> Enum.join("\n")

    %{
      type: @message,
      data: %{
        content: content
      }
    }
  rescue
    e in NoBossError ->
      %{
        type: @message,
        data: %{
          content: "**#{e.message}**"
        }
      }
  end

  def handle_interaction(%Interaction{data: %{name: "oof"}} = _interaction) do
    players = Players.get_death_count_by_player()

    content = get_death_message_content(players)

    %{
      type: @message,
      data: %{
        content: content
      }
    }
  end

  def handle_interaction(_) do
    %{type: @message, data: %{content: "N/A"}}
  end

  defp get_boss_message_content(boss) do
    grouped_players =
      Players.get_all_players()
      |> Enum.group_by(& &1.group, & &1.display_name)
      |> Enum.map(fn {group, players} ->
        Tuple.insert_at(DiscordBot.Bosses.get_group_boss(players, boss), 2, group)
      end)

    total = Enum.map(grouped_players, &elem(&1, 0)) |> Enum.sum()
    boss_name = DiscordBot.Bosses.boss_display_name(boss)

    if total > 0 do
      player_totals =
        grouped_players
        |> Enum.flat_map(fn {_, player_counts, group} ->
          player_counts
          |> Enum.filter(fn {_, count} -> count > 0 end)
          |> Enum.map(fn {player, count} ->
            if is_nil(group) do
              {player, count}
            else
              {"[#{group}] #{player}", count}
            end
          end)
        end)
        |> Enum.sort_by(&elem(&1, 1), :desc)

      left_len = padding_fn(player_totals |> Enum.map(&elem(&1, 0)))

      content =
        player_totals
        |> Enum.map(fn {player, count} ->
          "#{left_len.(player)}: #{count}"
        end)
        |> Enum.join("\n")

      boss_totals =
        grouped_players
        |> Enum.reject(fn {_, _, group} -> group === :unspecified end)
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

  defp get_death_message_content(players) do
    left_len = padding_fn(players |> Enum.map(fn {player, _, _} -> player.display_name end))

    list_content =
      players
      |> Enum.sort_by(&elem(&1, 1), :desc)
      |> Enum.map(fn {player, pvm_count, pk_count} ->
        text = "#{left_len.(player.display_name)}: #{pvm_count}"

        if pk_count > 0 do
          "#{text} (+ #{pk_count})"
        else
          text
        end
      end)
      |> Enum.join("\n")

    "**Deaths:** PvM (+ PK)\n```\n#{list_content}\n```"
  end

  defp padding_fn(list) do
    left_len = list |> Enum.map(fn name -> String.length(name) end) |> Enum.max()

    fn name -> String.pad_leading(name, left_len) end
  end
end

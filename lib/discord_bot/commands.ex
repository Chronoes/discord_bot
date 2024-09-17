defmodule DiscordBot.Commands do
  alias Nostrum.Constants.ApplicationCommandOptionType
  alias Nostrum.Struct.Interaction
  alias DiscordBot.State
  alias DiscordBot.Errors.NoBossError

  # https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-interaction-callback-type
  @message 4
  @autocomplete_result 8

  def create_commands(guild_id) do
    allowed_commands = State.get_guild_commands(guild_id)

    if Enum.member?(allowed_commands, "kc") do
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

      Nostrum.Api.create_guild_application_command(guild_id, command)
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

    grouped_players =
      State.players()
      |> Enum.map(fn {group, players} ->
        Tuple.append(DiscordBot.Bosses.get_group_boss(players, boss), group)
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
            if group === :unspecified do
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

      %{
        type: @message,
        data: %{
          content: "**#{boss_name}: #{total}**#{group_boss_header}\n```\n#{content}\n```"
        }
      }
    else
      %{
        type: @message,
        data: %{
          content: "**#{boss_name}: #{total}**"
        }
      }
    end
  rescue
    e in NoBossError ->
      %{
        type: @message,
        data: %{
          content: "**#{e.message}**"
        }
      }
  end

  def handle_interaction(_) do
    %{type: @message, data: %{content: ":white_check_mark:"}}
  end

  defp padding_fn(list) do
    left_len = list |> Enum.map(fn name -> String.length(name) end) |> Enum.max()

    fn name -> String.pad_leading(name, left_len) end
  end
end

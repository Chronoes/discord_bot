defmodule DiscordBot.Commands do
  alias Nostrum.Constants.ApplicationCommandOptionType
  alias Nostrum.Struct.Interaction
  alias DiscordBot.State

  # https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-interaction-callback-type
  @message 4
  @autocomplete_result 8

  def create_commands(guild_id) do
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

  @spec handle_interaction(Interaction.t()) :: map()
  def handle_interaction(%Interaction{type: 4, data: %{name: "kc"}} = interaction) do
    %Interaction{data: %{options: options}} = interaction
    %{value: value} = Enum.find(options, fn opt -> opt.name === "name" end)

    bosses = DiscordBot.Bosses.get_bosses()

    choices =
      case value do
        "" ->
          Enum.shuffle(bosses)

        value ->
          regex = Regex.compile!(value, "i")

          bosses
          |> Stream.map(fn boss ->
            case Regex.run(regex, boss, return: :index) do
              nil -> nil
              [{idx, _}] -> {idx, boss}
            end
          end)
          |> Stream.reject(&is_nil/1)
          |> Enum.sort_by(&elem(&1, 0))
          |> Enum.map(&elem(&1, 1))
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

    {{boss_name, total}, player_counts} = DiscordBot.Bosses.get_group_boss(State.players(), value)

    if total > 0 do
      player_totals =
        player_counts
        |> Enum.filter(fn {_, count} -> count > 0 end)
        |> Enum.sort_by(&elem(&1, 1), :desc)

      left_len = padding_fn(player_totals |> Enum.map(&elem(&1, 0)))

      content =
        player_totals
        |> Enum.map(fn {player, count} ->
          "#{left_len.(player)}: #{count}"
        end)
        |> Enum.join("\n")

      boss_name = DiscordBot.Bosses.boss_display_name(boss_name)

      %{
        type: @message,
        data: %{
          content: "**#{boss_name}: #{total}**\n```\n#{content}\n```"
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
  end

  def handle_interaction(_) do
    %{type: @message, data: %{content: ":white_check_mark:"}}
  end

  defp padding_fn(list) do
    left_len = list |> Enum.map(fn name -> String.length(name) end) |> Enum.max()

    fn name -> String.pad_leading(name, left_len) end
  end
end

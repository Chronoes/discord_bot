defmodule DiscordBot.KillCount do
  alias DiscordBot.Players

  @doc """
  Builds /kc message content for `boss` and its related bosses.
  """
  @spec content(DiscordBot.Bosses.boss()) :: String.t()
  def content(boss) do
    players = Players.get_all_players()

    # Fetch all uncached players concurrently up front, so that related bosses
    # below are served from the same results
    results =
      players
      |> Enum.map(& &1.display_name)
      |> DiscordBot.Bosses.get_players_bosses()
      |> Map.new()

    DiscordBot.Bosses.get_related_bosses(boss)
    |> Enum.map(&get_boss_message_content(&1, players, results))
    |> Enum.join("\n")
  end

  # Each entry is {group the count contributes to, contributed count, displayed row}.
  # Former members contribute their frozen KC to their old group, and only KC gained
  # since leaving to their current group (or solo).
  defp get_boss_entries(boss, players, results) do
    Enum.flat_map(players, fn player ->
      frozen =
        Enum.map(player.former_memberships, fn membership ->
          count = Map.get(membership.bosses, boss, 0)
          label = "[#{membership.group}] #{player.display_name} (left)"
          {membership.group, count, {:ok, label, count}}
        end)

      frozen_total = frozen |> Enum.map(&elem(&1, 1)) |> Enum.sum()
      label = player_label(player)

      current =
        case Map.fetch!(results, player.display_name) do
          {:ok, player_bosses} ->
            count = Map.get(player_bosses, boss, 0)
            {player.group, max(count - frozen_total, 0), {:ok, label, count}}

          {:error, msg} ->
            {player.group, 0, {:error, label, msg}}
        end

      [current | frozen]
    end)
  end

  defp player_label(%Players.Player{group: nil} = player) do
    case Players.Player.mode_tag(player) do
      nil -> player.display_name
      tag -> "[#{tag}] #{player.display_name}"
    end
  end

  defp player_label(%Players.Player{} = player), do: "[#{player.group}] #{player.display_name}"

  defp get_boss_message_content(boss, players, results) do
    entries = get_boss_entries(boss, players, results)

    total = entries |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    boss_name = DiscordBot.Bosses.boss_display_name(boss)

    if total > 0 do
      player_totals =
        entries
        |> Enum.map(&elem(&1, 2))
        |> Enum.filter(fn
          {:ok, _label, count} -> count > 0
          {:error, _label, _msg} -> true
        end)
        |> Enum.map(fn {_status, label, value} -> {label, value} end)
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
        entries
        |> Enum.reject(fn {group, _, _} -> is_nil(group) end)
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        |> Enum.map(fn {group, counts} -> "[#{group}]: #{Enum.sum(counts)}" end)

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

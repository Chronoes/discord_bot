defmodule DiscordBot.PeriodicOof do
  require Logger
  alias DiscordBot.Guilds
  alias DiscordBot.Deaths

  # First scheduled send; every following send lands exactly 14 days after this.
  @anchor_date ~D[2026-08-16]
  @period_days 14
  @guild_name "GIM ainid"

  def tasks do
    [
      %{
        id: :periodic_oof,
        start: {
          SchedEx,
          :run_every,
          [
            __MODULE__,
            :send_report,
            [:sched_ex_scheduled_time],
            "0 23 * * 0",
            [timezone: "Europe/Tallinn"]
          ]
        }
      }
    ]
  end

  def send_report(exec_time) do
    exec_date = DateTime.to_date(exec_time)

    if due?(exec_date) do
      since_date = Date.add(exec_date, -@period_days)
      content = Deaths.report(since_date)

      case Guilds.get_guild_by_name(@guild_name) do
        nil ->
          Logger.warning("Guild #{@guild_name} not found, skipping periodic oof report")

        guild ->
          guild.channels
          |> Enum.filter(&Enum.member?(&1.actions, :deaths))
          |> Enum.each(fn channel ->
            Nostrum.Api.Message.create(channel.channel_id, content: content)
          end)
      end
    end
  end

  defp due?(exec_date) do
    Date.diff(exec_date, @anchor_date)
    |> rem(@period_days) == 0
  end
end

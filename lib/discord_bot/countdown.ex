defmodule DiscordBot.Countdown do
  require Logger
  @event_date ~U[2024-11-27 12:30:00Z]
  @channel_id 1_179_025_071_692_578_927
  # @channel_id 1_111_266_719_370_055_741

  def tasks do
    [
      # %{
      #   id: "daily_reminder",
      #   start: {
      #     SchedEx,
      #     :run_every,
      #     [__MODULE__, :daily_reminder, [:sched_ex_scheduled_time], "0 15 * * *"]
      #   }
      # },
      # %{
      #   id: "hourly_reminder",
      #   start: {
      #     SchedEx,
      #     :run_every,
      #     [__MODULE__, :hourly_reminder, [:sched_ex_scheduled_time], "0 6-15 * * *"]
      #   }
      # }
    ]
  end

  def daily_reminder(exec_time) do
    if DateTime.before?(exec_time, @event_date) do
      ref_time = DateTime.add(exec_time, -1, :hour)

      days_left = Date.diff(@event_date, ref_time)

      Nostrum.Api.Message.create(@channel_id,
        content:
          "**#{days_left} #{if days_left == 1, do: "päev", else: "päeva"} liiga alguseni!**"
      )
    end
  end

  def hourly_reminder(exec_time) do
    if DateTime.to_date(exec_time) == DateTime.to_date(@event_date) do
      if DateTime.before?(exec_time, @event_date) do
        ref_time = DateTime.add(exec_time, -1, :minute)

        hours_left = DateTime.diff(@event_date, ref_time, :hour)

        Nostrum.Api.Message.create(@channel_id,
          content:
            "**#{if hours_left == 1, do: "Üks tund", else: "#{hours_left} tundi"} veel liigani!**"
        )
      else
        if DateTime.diff(@event_date, exec_time, :minute) <= 1 do
          Nostrum.Api.Message.create(@channel_id, content: "**Liiga on alanud!** loodetavasti")
        end
      end
    end
  end
end

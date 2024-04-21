defmodule DiscordBot.Competition do
  use GenServer
  require Logger
  alias Nostrum.Struct.Message
  alias DiscordBot.TempleOsrs

  @type comp_id :: binary() | integer()

  defstruct in_progress: false, refresh_ref: nil

  defp get_refresh_time() do
    now = DateTime.utc_now()
    timestamp = Time.new!(23, 0, 0)
    # end time sunday of the current week
    end_time = DateTime.new!(Date.end_of_week(now), timestamp)

    if DateTime.after?(now, end_time) do
      # In case it's not new week yet
      DateTime.new!(Date.end_of_week(DateTime.add(now, 1, :hour)), timestamp)
    else
      end_time
    end
  end

  defp calculate_pre_end_time(end_time) do
    DateTime.diff(end_time, DateTime.utc_now(), :millisecond)
  end

  defp setup_comp_refresh(state, comp_id),
    do: setup_comp_refresh(state, comp_id, get_refresh_time())

  defp setup_comp_refresh(state, comp_id, refresh_time) do
    if state.refresh_ref do
      time_left = Process.cancel_timer(state.refresh_ref)

      if time_left !== false and time_left > 0 do
        Logger.info("Cancelling competition refresh due in #{time_left} ms")
      end
    end

    milliseconds = calculate_pre_end_time(refresh_time)

    Logger.info(
      "Setting up competition refresh for #{comp_id} at #{DateTime.to_string(refresh_time)} (#{milliseconds} ms)"
    )

    ref = Process.send_after(self(), {:run_comp_update, comp_id}, milliseconds)
    %{state | refresh_ref: ref}
  end

  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      %__MODULE__{in_progress: false, refresh_ref: nil},
      name: __MODULE__
    )
  end

  @impl true
  def init(state) do
    send(self(), :setup_comp_refresh)
    {:ok, state}
  end

  defp fetch_members(comp_id) do
    response = TempleOsrs.fetch_competition_members(comp_id)
    response.body
  end

  @spec update_player_datapoints(comp_id()) :: term()
  def update_player_datapoints(comp_id) do
    GenServer.call(__MODULE__, {:update_player_datapoints, comp_id})
  end

  @spec time_remaining_for_update() :: DateTime.t() | false
  @spec time_remaining_for_update(true) :: pos_integer() | false
  @spec time_remaining_for_update(false) :: DateTime.t() | false
  def time_remaining_for_update(in_ms \\ false) do
    ms = GenServer.call(__MODULE__, :time_remaining_for_update)

    if ms == false do
      false
    else
      if in_ms do
        ms
      else
        DateTime.add(DateTime.utc_now(), ms, :millisecond)
      end
    end
  end

  @spec change_refresh_time(comp_id(), DateTime.t()) :: :ok
  def change_refresh_time(comp_id, refresh_time) do
    GenServer.cast(__MODULE__, {:change_refresh_time, comp_id, refresh_time})
  end

  def check_message(%Message{content: content} = _message) do
    if String.contains?(content, "templeosrs.com/competitions") do
      case Regex.run(~r/id=(\d+)/, content) do
        [_, comp_id] ->
          {:ok, comp_id}

        _ ->
          :noop
      end
    else
      :noop
    end
  end

  @impl true
  def handle_call({:update_player_datapoints, comp_id}, _from, state) do
    comp_id = to_string(comp_id)

    if state.in_progress do
      Logger.info("Competition #{state.in_progress} datapoint update already in progress")
      {:reply, state.in_progress, state}
    else
      send(self(), {:run_comp_update, comp_id})
      {:reply, comp_id, %{state | in_progress: comp_id}}
    end
  end

  @impl true
  def handle_call(:time_remaining_for_update, _from, state) do
    {:reply, Process.read_timer(state.refresh_ref), state}
  end

  @impl true
  def handle_cast({:end_comp_update, _comp_id}, state) do
    {:noreply, %{state | in_progress: false}}
  end

  @impl true
  def handle_cast({:change_refresh_time, comp_id, refresh_time}, state) do
    {:noreply, setup_comp_refresh(state, to_string(comp_id), refresh_time)}
  end

  @impl true
  def handle_info({:run_comp_update, comp_id}, state) do
    Task.start(fn ->
      players = fetch_members(comp_id)
      player_count = Enum.count(players)

      interval = 12_000

      # Sleep interval + 1s processing time per player
      expected_finish =
        DateTime.add(DateTime.utc_now(), player_count * (interval + 1000), :millisecond)

      Logger.info(
        "Updating datapoints for #{player_count} members of competition #{comp_id}. Predicted finish: #{DateTime.to_string(expected_finish)}"
      )

      Enum.each(players, fn player ->
        try do
          TempleOsrs.add_player_datapoint(player)
        rescue
          _ -> Logger.error("Failed to update datapoint for player #{player}")
        end

        Process.sleep(interval)
      end)

      Logger.info("Competition #{comp_id} datapoint update complete")
      GenServer.cast(__MODULE__, {:end_comp_update, comp_id})
    end)

    state = setup_comp_refresh(state, comp_id)
    {:noreply, %{state | in_progress: comp_id}}
  end

  @impl true
  def handle_info(:setup_comp_refresh, state) do
    comp_id =
      DiscordBot.State.get_registered_guilds()
      |> Enum.flat_map(fn {_guild_id, guild} ->
        guild.channels
        |> Enum.filter(fn {_channel_id, channel} ->
          Enum.member?(channel.actions, :competition)
        end)
        |> Enum.flat_map(fn {channel_id, _channel} ->
          case Nostrum.Api.get_channel_messages(channel_id, 5) do
            {:ok, messages} ->
              messages
              |> Enum.map(fn msg ->
                case check_message(msg) do
                  :noop ->
                    nil

                  {:ok, comp_id} ->
                    comp_id
                end
              end)
              |> Enum.reject(&is_nil/1)

            {:error, err} ->
              Logger.error(
                "Channel #{channel_id} received HTTP #{err.status_code}, Discord error #{err.response.code}: #{err.response.message}"
              )

              []
          end
        end)
      end)
      |> List.first()

    if comp_id do
      {:noreply, setup_comp_refresh(state, comp_id)}
    else
      {:noreply, state}
    end
  end
end

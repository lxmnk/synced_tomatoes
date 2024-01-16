defmodule SyncedTomatoes.Core.Timer do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    work_min = Keyword.fetch!(opts, :work_min)
    short_break_min = Keyword.fetch!(opts, :short_break_min)
    long_break_min = Keyword.fetch!(opts, :long_break_min)
    work_intervals_count = Keyword.fetch!(opts, :work_intervals_count)
    auto_next = Keyword.fetch!(opts, :auto_next)

    time_left_ms = Keyword.get(opts, :time_left_ms)
    interval_type = Keyword.get(opts, :interval_type, :work)
    current_work_interval = Keyword.get(opts, :current_work_interval, 1)

    timer_ref = Process.send_after(
      self(), :work_finished, time_left_ms || :timer.minutes(work_min)
    )

    {:ok, %{
      work_min: work_min,
      short_break_min: short_break_min,
      long_break_min: long_break_min,
      work_intervals_count: work_intervals_count,
      auto_next: auto_next,

      ticking?: true,
      interval_type: interval_type,
      current_work_interval: current_work_interval,
      timer_ref: timer_ref,
      saved_timer_value: nil
    }}
  end

  def get_status(pid) do
    GenServer.call(pid, :status)
  end

  def pause(pid) do
    GenServer.call(pid, :pause)
  end

  def continue(pid) do
    GenServer.call(pid, :continue)
  end

  @impl true
  def handle_call(:status, _, state) do
    time_left_ms =
      if state.timer_ref do
        Process.read_timer(state.timer_ref)
      else
        state.saved_timer_value
      end

    response = %{
      ticking?: state.ticking?,
      interval_type: state.interval_type,
      time_left_ms: time_left_ms,
      current_work_interval: state.current_work_interval,
    }

    {:reply, response, state}
  end

  @impl true
  def handle_call(:pause, _, %{ticking?: false} = state) do
    {:reply, {:error, :already_paused}, state}
  end
  def handle_call(:pause, _, %{timer_ref: timer_ref} = state) do
    saved_timer_value =
      case Process.cancel_timer(timer_ref) do
        value when is_integer(value) ->
          value

        _ ->
          0
      end

    {:reply, :ok, %{state | ticking?: false, timer_ref: nil, saved_timer_value: saved_timer_value}}
  end

  @impl true
  def handle_call(:continue, _, %{ticking?: true} = state) do
    {:reply, {:error, :already_ticking}, state}
  end
  def handle_call(:continue, _, %{saved_timer_value: saved_timer_value} = state) do
    timer_ref = Process.send_after(self(), :work_finished, saved_timer_value)

    {:reply, :ok, %{state | ticking?: true, timer_ref: timer_ref, saved_timer_value: nil}}
  end

  @impl true
  def handle_info(:work_finished, state) do
    {next_interval_type, next_interval_min} =
      if state.current_work_interval == state.work_intervals_count do
        {:long_break, state.long_break_min}
      else
        {:short_break, state.short_break_min}
      end

    if state.auto_next do
      timer_ref = Process.send_after(
        self(), next_interval_type, :timer.minutes(next_interval_min)
      )

      {:noreply, %{state | interval_type: next_interval_type, timer_ref: timer_ref}}
    else
      {:noreply, %{
        state |
          interval_type: next_interval_type,
          ticking?: false,
          timer_ref: nil,
          saved_timer_value: :timer.minutes(next_interval_min)
      }}
    end
  end

  @impl true
  def handle_info(
    :short_break_finished,
    %{
      work_min: work_min,
      current_work_interval: current_work_interval,
      auto_next: true
    } = state
  )
  do
    timer_ref = Process.send_after(self(), :work_finished, :timer.minutes(work_min))

    {:noreply, %{
      state |
        interval_type: :work,
        timer_ref: timer_ref,
        current_work_interval: current_work_interval + 1
    }}
  end
  def handle_info(
    :short_break_finished,
    %{
      work_min: work_min,
      current_work_interval: current_work_interval,
      auto_next: false
    } = state
  )
  do
    {:noreply, %{
      state |
        interval_type: :work,
        ticking?: false,
        timer_ref: nil,
        saved_timer_value: :timer.minutes(work_min),
        current_work_interval: current_work_interval + 1
    }}
  end

  @impl true
  def handle_info(:long_break_finished, %{work_min: work_min, auto_next: true} = state) do
    timer_ref = Process.send_after(self(), :work_finished, :timer.minutes(work_min))

    {:noreply, %{state | interval_type: :work, timer_ref: timer_ref, current_work_interval: 1}}
  end
  def handle_info(:long_break_finished, %{work_min: work_min, auto_next: false} = state) do
    {:noreply, %{
      state |
        interval_type: :work,
        ticking?: false,
        timer_ref: nil,
        saved_timer_value: :timer.minutes(work_min),
        current_work_interval: 1
    }}
  end
end

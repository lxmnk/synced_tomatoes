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

    timer_ref = Process.send_after(self(), :work_finished, :timer.minutes(work_min))

    {:ok, %{
      work_min: work_min,
      short_break_min: short_break_min,
      long_break_min: long_break_min,
      work_intervals_count: work_intervals_count,

      ticking?: true,
      interval_type: :work,
      current_work_interval: 1,
      timer_ref: timer_ref,
      saved_timer_value: nil
    }}
  end

  def get_status(pid) do
    GenServer.call(pid, :status)
  end

  def pause(pid) do
    GenServer.cast(pid, :pause)
  end

  def continue(pid) do
    GenServer.cast(pid, :continue)
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
  def handle_cast(:pause, %{ticking?: false} = state) do
    {:noreply, state}
  end
  def handle_cast(:pause, %{timer_ref: timer_ref} = state) do
    saved_timer_value =
      case Process.cancel_timer(timer_ref) do
        value when is_integer(value) ->
          value

        _ ->
          0
      end

    {:noreply, %{state | ticking?: false, timer_ref: nil, saved_timer_value: saved_timer_value}}
  end

  def handle_cast(:continue, %{ticking?: true} = state) do
    {:noreply, state}
  end
  def handle_cast(:continue, %{saved_timer_value: saved_timer_value} = state) do
    timer_ref = Process.send_after(self(), :work_finished, saved_timer_value)

    {:noreply, %{state | ticking?: true, timer_ref: timer_ref, saved_timer_value: nil}}
  end

  @impl true
  def handle_info(
    :work_finished,
    %{
      current_work_interval: work_intervals_count,
      work_intervals_count: work_intervals_count,
      long_break_min: long_break_min
    } = state
  )
  do
    timer_ref = Process.send_after(self(), :long_break_finished, :timer.minutes(long_break_min))

    {:noreply, %{state | interval_type: :long_break, timer_ref: timer_ref}}
  end
  def handle_info(:work_finished, %{short_break_min: short_break_min} = state) do
    timer_ref = Process.send_after(self(), :short_break_finished, :timer.minutes(short_break_min))

    {:noreply, %{state | interval_type: :short_break, timer_ref: timer_ref}}
  end

  @impl true
  def handle_info(
    :short_break_finished,
    %{
      work_min: work_min,
      current_work_interval: current_work_interval
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

  @impl true
  def handle_info(:long_break_finished, %{work_min: work_min} = state) do
    timer_ref = Process.send_after(self(), :work_finished, :timer.minutes(work_min))

    {:noreply, %{state | interval_type: :work, timer_ref: timer_ref, current_work_interval: 1}}
  end
end

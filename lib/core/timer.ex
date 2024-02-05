defmodule SyncedTomatoes.Core.Timer do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    interval_min = %{
      work: Keyword.fetch!(opts, :work_min),
      short_break: Keyword.fetch!(opts, :short_break_min),
      long_break: Keyword.fetch!(opts, :long_break_min)
    }

    work_intervals_count = Keyword.fetch!(opts, :work_intervals_count)
    auto_next = Keyword.fetch!(opts, :auto_next)

    time_left_ms = Keyword.get(opts, :time_left_ms)
    interval_type = Keyword.get(opts, :interval_type, :work)
    current_work_interval = Keyword.get(opts, :current_work_interval, 1)

    notify_pid = Keyword.get(opts, :notify_pid)

    timer_ref = Process.send_after(
      self(),
      interval_finished(interval_type),
      time_left_ms || interval_ms(interval_min, interval_type)
    )

    {:ok, %{
      interval_min: interval_min,
      work_intervals_count: work_intervals_count,
      auto_next: auto_next,

      ticking?: true,
      interval_type: interval_type,
      current_work_interval: current_work_interval,
      timer_ref: timer_ref,
      saved_timer_value: nil,

      notify_pid: notify_pid
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

  def sync(pid, sync_data) do
    GenServer.call(pid, {:sync, sync_data})
  end

  @impl true
  def handle_call(:status, _, %{ticking?: ticking?} = state) do
    time_left_ms =
      if ticking? do
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
  def handle_call(:continue, _, state) do
    timer_ref = Process.send_after(
      self(), interval_finished(state.interval_type), state.saved_timer_value
    )

    {:reply, :ok, %{state | ticking?: true, timer_ref: timer_ref, saved_timer_value: nil}}
  end

  @impl true
  def handle_call({:sync, _}, _, %{ticking?: true} = state) do
    {:reply, {:error, :timer_ticking}, state}
  end
  def handle_call({:sync, %{interval_type: interval_type} = sync_data}, _, state)
      when interval_type in ~w(work short_break long_break)a
  do
    {:reply, :ok, %{
      state |
        interval_type: interval_type,
        current_work_interval: sync_data.current_work_interval,
        saved_timer_value: sync_data.time_left_ms
    }}
  end

  @impl true
  def handle_info(:work_finished, state) do
    notify(state, :work_finished)

    next_interval_type =
      if state.current_work_interval == state.work_intervals_count do
        :long_break
      else
        :short_break
      end

    next_interval_ms = interval_ms(state.interval_min, next_interval_type)

    if state.auto_next do
      timer_ref = Process.send_after(self(), next_interval_type, next_interval_ms)

      {:noreply, %{state | interval_type: next_interval_type, timer_ref: timer_ref}}
    else
      {:noreply, %{
        state |
          interval_type: next_interval_type,
          ticking?: false,
          timer_ref: nil,
          saved_timer_value: next_interval_ms
      }}
    end
  end

  @impl true
  def handle_info(:short_break_finished, state) do
    notify(state, :short_break_finished)

    if state.auto_next do
      timer_ref = Process.send_after(
        self(),
        :work_finished,
        interval_ms(state.interval_min, :work)
      )

      {:noreply, %{
        state |
          interval_type: :work,
          timer_ref: timer_ref,
          current_work_interval: state.current_work_interval + 1
      }}
    else
      {:noreply, %{
        state |
          interval_type: :work,
          ticking?: false,
          timer_ref: nil,
          saved_timer_value: interval_ms(state.interval_min, :work),
          current_work_interval: state.current_work_interval + 1
      }}
    end
  end

  @impl true
  def handle_info(:long_break_finished, state) do
    notify(state, :long_break_finished)

    if state.auto_next do
      timer_ref = Process.send_after(
        self(),
        :work_finished,
        interval_ms(state.interval_min, :work)
      )

      {:noreply, %{
        state |
          interval_type: :work,
          timer_ref: timer_ref,
          current_work_interval: 1
      }}
    else
      {:noreply, %{
        state |
          interval_type: :work,
          ticking?: false,
          timer_ref: nil,
          saved_timer_value: interval_ms(state.interval_min, :work),
          current_work_interval: 1
      }}
    end
  end

  defp interval_finished(:work), do: :work_finished
  defp interval_finished(:short_break), do: :short_break_finished
  defp interval_finished(:long_break), do: :long_break_finished

  defp interval_ms(interval_min, interval_type) do
    :timer.minutes(Map.fetch!(interval_min, interval_type))
  end

  defp notify(%{notify_pid: pid}, message) when is_pid(pid) do
    send(pid, message)
  end
  defp notify(_, _) do
    :ok
  end
end

defmodule SyncedTomatoes.Core.Commands.StartTimer do
  alias SyncedTomatoes.Core.{Settings, Timer, TimerDump, TimerSupervisor}
  alias SyncedTomatoes.Repos.Postgres
  alias SyncedTomatoes.Web.WebSocketRegistry

  def execute(user_id) do
    case TimerSupervisor.fetch_timer(user_id) do
      {:ok, timer} ->
        Timer.continue(timer)

      {:error, :not_found} ->
        start_timer(user_id)
    end
  end

  def start_timer(user_id) do
    settings = Postgres.get!(Settings, user_id)
    timer_dump = Postgres.get(TimerDump, user_id)

    timer_opts = [
      work_min: settings.work_min,
      short_break_min: settings.short_break_min,
      long_break_min: settings.long_break_min,
      work_intervals_count: settings.work_intervals_count,
      auto_next: settings.auto_next,
      notify_fun: fn message -> WebSocketRegistry.publish_to_all(user_id, message) end
    ]

    timer_opts = maybe_load_timer_dump(timer_opts, timer_dump)

    case TimerSupervisor.start_timer(user_id, timer_opts) do
      {:ok, _} ->
        :ok

      error ->
        error
    end
  end

  defp maybe_load_timer_dump(timer_opts, nil) do
    timer_opts
  end
  defp maybe_load_timer_dump(timer_opts, %TimerDump{} = dump) do
    Keyword.merge(
      timer_opts,
      [
        interval_type: String.to_atom(dump.interval_type),
        current_work_interval: dump.current_work_interval,
        time_left_ms: dump.time_left_ms
      ]
    )
  end
end

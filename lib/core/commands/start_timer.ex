defmodule SyncedTomatoes.Core.Commands.StartTimer do
  alias SyncedTomatoes.Core.Queries.GetSettings
  alias SyncedTomatoes.Core.{Timer, TimerManager}

  def execute(user_id) do
    case TimerManager.fetch_timer(user_id) do
      {:ok, timer} ->
        Timer.continue(timer)

      {:error, :not_found} ->
        start_timer(user_id)
    end
  end

  def start_timer(user_id) do
    with {:ok, settings} <- GetSettings.execute(user_id) do
      timer_settings = [
        work_min: settings.work_min,
        short_break_min: settings.short_break_min,
        long_break_min: settings.long_break_min,
        work_intervals_count: settings.work_intervals_count,
        auto_next: settings.auto_next,
      ]

      case TimerManager.start_timer(user_id, timer_settings) do
        {:ok, _} ->
          :ok

        error ->
          error
      end
    end
  end
end

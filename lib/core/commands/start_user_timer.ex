defmodule SyncedTomatoes.Core.Queries.StartUserTimer do
  alias SyncedTomatoes.Core.Queries.GetSettings
  alias SyncedTomatoes.Core.TimerManager

  def execute(user_id) do
    with {:ok, settings} <- GetSettings.execute(user_id) do
      timer_settings = [
        work_min: settings.work_min,
        short_break_min: settings.short_break_min,
        long_break_min: settings.long_break_min,
        work_intervals_count: settings.work_intervals_count,
        auto_next: settings.auto_next,
      ]

      TimerManager.start_timer(user_id, timer_settings)
    end
  end
end

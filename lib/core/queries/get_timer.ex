defmodule SyncedTomatoes.Core.Queries.GetTimer do
  alias SyncedTomatoes.Core.Queries.GetSettings
  alias SyncedTomatoes.Core.{Timer, TimerManager}

  def execute(user_id) do
    case TimerManager.fetch_timer(user_id) do
      {:ok, timer} ->
        {:ok,
          timer
          |> Timer.get_status()
          |> map_status()
        }

      {:error, :not_found} ->
        with {:ok, settings} <- GetSettings.execute(user_id) do
          {:ok, map_settings(settings)}
        end
    end
  end

  defp map_settings(settings) do
    %{
      state: :stopped,
      interval_type: :work,
      time_left_ms: :timer.minutes(settings.work_min),
      current_work_interval: 1
    }
  end

  defp map_status(status) do
    %{
      state: (if status.ticking?, do: :ticking, else: :paused),
      interval_type: status.interval_type,
      time_left_ms: status.time_left_ms,
      current_work_interval: status.current_work_interval
    }
  end
end
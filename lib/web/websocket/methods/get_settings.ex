defmodule SyncedTomatoes.Web.WebSocket.Methods.GetSettings do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Queries.GetSettings

  @impl true
  def execute(context, _) do
    GetSettings.execute(context.user_id)
  end

  @impl true
  def map_result(result) do
    %{
      "workMin" => result.work_min,
      "shortBreakMin" => result.short_break_min,
      "longBreakMin" => result.long_break_min,
      "workIntervalsCount" => result.work_intervals_count
    }
  end
end

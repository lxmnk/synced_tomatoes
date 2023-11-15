defmodule SyncedTomatoes.Web.WebSocket.Methods.GetTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Queries.GetUserTimer

  def execute(context, _) do
    GetUserTimer.execute(context.user_id)
  end

  def map_result(result) do
    %{
      "state" => result.state,
      "intervalType" => result.interval_type,
      "timeLeftMs" => result.time_left_ms,
      "currentWorkInterval" => result.current_work_interval
    }
  end
end

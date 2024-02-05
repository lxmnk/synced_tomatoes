defmodule SyncedTomatoes.Web.WebSocket.Methods.GetTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Queries.GetTimer

  @impl true
  def execute(context, _) do
    GetTimer.execute(context.user_id)
  end

  @impl true
  def map_result(result) do
    %{
      state: result.state,
      intervalType: result.interval_type,
      timeLeftMs: result.time_left_ms,
      currentWorkInterval: result.current_work_interval
    }
  end
end

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
      intervalType: map_inteval_type(result.interval_type),
      timeLeftMs: result.time_left_ms,
      currentWorkInterval: result.current_work_interval
    }
  end

  defp map_inteval_type(:work), do: "work"
  defp map_inteval_type(:short_break), do: "shortBreak"
  defp map_inteval_type(:long_break), do: "longBreak"
end

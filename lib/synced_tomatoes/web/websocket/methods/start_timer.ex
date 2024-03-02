defmodule SyncedTomatoes.Web.WebSocket.Methods.StartTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.StartTimer
  alias SyncedTomatoes.Web.WebSocket.Methods.GetTimer
  alias SyncedTomatoes.Web.WebSocketRegistry

  @impl true
  def execute(context, _) do
    with :ok <- StartTimer.execute(context.user_id),
         {:ok, timer_info} <- GetTimer.call(context, %{})
    do
      event = %{event: "timerStarted", payload: timer_info}
      WebSocketRegistry.publish_to_other(context.user_id, context.device_id, event)

      {:ok, timer_info}
    else
      {:error, :already_ticking} ->
        {:error, "Already ticking"}

      error ->
        error
    end
  end
end

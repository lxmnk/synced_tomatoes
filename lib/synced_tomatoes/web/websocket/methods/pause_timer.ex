defmodule SyncedTomatoes.Web.WebSocket.Methods.PauseTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.PauseTimer
  alias SyncedTomatoes.Web.WebSocket.Methods.GetTimer
  alias SyncedTomatoes.Web.WebSocketRegistry

  @impl true
  def execute(context, _) do
    with :ok <- PauseTimer.execute(context.user_id),
         {:ok, timer_info} <- GetTimer.call(context, %{})
    do
      event = %{event: "timerPaused", payload: timer_info}
      WebSocketRegistry.publish_to_other(context.user_id, context.device_id, event)

      {:ok, timer_info}
    else
      {:error, :not_found} ->
        {:error, "Timer not started"}

      {:error, :already_paused} ->
        {:error, "Already paused"}

      error ->
        error
    end
  end
end

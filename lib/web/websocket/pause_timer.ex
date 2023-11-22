defmodule SyncedTomatoes.Web.WebSocket.Methods.PauseTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.StartUserTimer

  def execute(context, _) do
    case StartUserTimer.execute(context.user_id) do
      {:error, :not_found} ->
        {:error, "Timer not started"}

      {:error, :already_paused} ->
        {:error, "Already paused"}

      result ->
        result
    end
  end
end

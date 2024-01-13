defmodule SyncedTomatoes.Web.WebSocket.Methods.PauseTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.PauseTimer

  @impl true
  def execute(context, _) do
    case PauseTimer.execute(context.user_id) do
      {:error, :not_found} ->
        {:error, "Timer not started"}

      {:error, :already_paused} ->
        {:error, "Already paused"}

      result ->
        result
    end
  end
end

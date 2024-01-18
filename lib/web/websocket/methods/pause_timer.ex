defmodule SyncedTomatoes.Web.WebSocket.Methods.PauseTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.PauseTimer
  alias SyncedTomatoes.Core.Queries.GetTimer

  @impl true
  def execute(context, _) do
    case PauseTimer.execute(context.user_id) do
      :ok ->
        GetTimer.execute(context.user_id)

      {:error, :not_found} ->
        {:error, "Timer not started"}

      {:error, :already_paused} ->
        {:error, "Already paused"}

      error ->
        error
    end
  end
end

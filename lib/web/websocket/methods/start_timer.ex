defmodule SyncedTomatoes.Web.WebSocket.Methods.StartTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.StartTimer
  alias SyncedTomatoes.Core.Queries.GetTimer

  @impl true
  def execute(context, _) do
    case StartTimer.execute(context.user_id) do
      :ok ->
        GetTimer.execute(context.user_id)

      {:error, :already_ticking} ->
        {:error, "Already ticking"}

      error ->
        error
    end
  end
end

defmodule SyncedTomatoes.Web.WebSocket.Methods.StartTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Queries.StartUserTimer

  @impl true
  def execute(context, _) do
    case StartUserTimer.execute(context.user_id) do
      {:error, :already_started} ->
        {:error, "Already started"}

      result ->
        result
    end
  end
end

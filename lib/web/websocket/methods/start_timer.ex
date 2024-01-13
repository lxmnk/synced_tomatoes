defmodule SyncedTomatoes.Web.WebSocket.Methods.StartTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.StartTimer

  @impl true
  def execute(context, _) do
    case StartTimer.execute(context.user_id) do
      {:error, :already_ticking} ->
        {:error, "Already ticking"}

      result ->
        result
    end
  end
end

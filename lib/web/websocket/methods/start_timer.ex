defmodule SyncedTomatoes.Web.WebSocket.Methods.StartTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.StartTimer
  alias SyncedTomatoes.Web.WebSocket.Methods.GetTimer

  @impl true
  def execute(context, _) do
    case StartTimer.execute(context.user_id) do
      :ok ->
        GetTimer.call(context, %{})

      {:error, :already_ticking} ->
        {:error, "Already ticking"}

      error ->
        error
    end
  end
end

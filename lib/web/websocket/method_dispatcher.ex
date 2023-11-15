defmodule SyncedTomatoes.Web.WebSocket.MethodDispatcher do
  alias SyncedTomatoes.Web.WebSocket.Methods.{
    GetSettings,
    GetTimer,
    UpdateSettings
  }

  def dispatch("get_settings", context, params) do
    GetSettings.call(context, params)
  end

  def dispatch("get_timer", context, params) do
    GetTimer.execute(context, params)
  end

  def dispatch("update_settings", context, params) do
    UpdateSettings.call(context, params)
  end

  def dispatch(_, _, _) do
    {:error, "Method not found"}
  end
end

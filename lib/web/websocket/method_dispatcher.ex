defmodule SyncedTomatoes.Web.WebSocket.MethodDispatcher do
  alias SyncedTomatoes.Web.WebSocket.Methods.{
    GetSettings,
    GetTimer,
    PauseTimer,
    StartTimer,
    UpdateSettings
  }

  def dispatch("get_settings", context, params) do
    GetSettings.call(context, params)
  end

  def dispatch("get_timer", context, params) do
    GetTimer.execute(context, params)
  end

  def dispatch("pause_timer", context, params) do
    PauseTimer.execute(context, params)
  end

  def dispatch("start_timer", context, params) do
    StartTimer.execute(context, params)
  end

  def dispatch("update_settings", context, params) do
    UpdateSettings.call(context, params)
  end

  def dispatch(_, _, _) do
    {:error, "Method not found"}
  end
end

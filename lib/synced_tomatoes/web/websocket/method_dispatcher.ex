defmodule SyncedTomatoes.Web.WebSocket.MethodDispatcher do
  alias SyncedTomatoes.Web.WebSocket.Methods.{
    GetSettings,
    GetTimer,
    PauseTimer,
    StartTimer,
    SyncTimer,
    UpdateSettings
  }

  def dispatch("getSettings", context, params) do
    GetSettings.call(context, params)
  end

  def dispatch("updateSettings", context, params) do
    UpdateSettings.call(context, params)
  end

  def dispatch("startTimer", context, params) do
    StartTimer.call(context, params)
  end

  def dispatch("getTimer", context, params) do
    GetTimer.call(context, params)
  end

  def dispatch("pauseTimer", context, params) do
    PauseTimer.call(context, params)
  end

  def dispatch("syncTimer", context, params) do
    SyncTimer.call(context, params)
  end

  def dispatch(_, _, _) do
    {:error, "Method not found"}
  end
end

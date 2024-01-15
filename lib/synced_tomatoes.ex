defmodule SyncedTomatoes do
  @config Application.compile_env(:synced_tomatoes, :config_impl, SyncedTomatoes.Config)

  def http_port do
    @config.get(:http_port, 4000)
  end

  def websocket_cleanup_enabled? do
    @config.get(:websocket_cleanup_enabled?, true)
  end
end

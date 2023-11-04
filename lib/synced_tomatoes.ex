defmodule SyncedTomatoes do
  @http_port Application.compile_env(:synced_tomatoes, :http_port, 4000)

  def http_port do
    @http_port
  end
end

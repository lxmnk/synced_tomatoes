defmodule SyncedTomatoes.Config do
  def get(key, default \\ nil) do
    Application.get_env(:synced_tomatoes, key, default)
  end
end

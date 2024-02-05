defmodule SyncedTomatoes.Web.WebSocketRegistry do
  use Agent

  @registry_name :websocket_registry

  def start_link(_) do
    Registry.start_link(keys: :duplicate, name: @registry_name)
  end

  def add(user_id, udid) do
    Registry.register(@registry_name, user_id, udid)
  end

  def get_all(_user_id) do
  end

  def get_others(_user_id, _udid) do
  end
end

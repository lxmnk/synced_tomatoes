defmodule SyncedTomatoes.Web.WebSocketRegistry do
  use Agent

  @registry_name :websocket_registry

  def start_link(_) do
    Registry.start_link(keys: :duplicate, name: @registry_name)
  end

  def add(user_id, device_id) do
    Registry.register(@registry_name, user_id, device_id)
  end

  def only?(user_id, device_id) do
    case Registry.lookup(@registry_name, user_id) do
      [{_, ^device_id}] ->
        true

      _ ->
        false
    end
  end

  def publish_to_all(user_id, message) do
    Registry.dispatch(@registry_name, user_id, fn entries ->
      for {pid, _} <- entries do
        send(pid, message)
      end
    end)
  end

  def publish_to_other(user_id, current_device_id, message) do
    Registry.dispatch(@registry_name, user_id, fn entries ->
      for {pid, device_id} <- entries, device_id != current_device_id do
        send(pid, message)
      end
    end)
  end
end

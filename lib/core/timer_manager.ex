defmodule SyncedTomatoes.Core.TimerManager do
  use Supervisor

  alias SyncedTomatoes.Core.Timer

  @registry_name :timer_registry

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    registry_spec = {Registry, [keys: :unique, name: @registry_name]}

    Supervisor.init([registry_spec], strategy: :one_for_one)
  end

  def start_timer(user_id, timer_opts) do
    spec = timer_spec(user_id, timer_opts)

    case Supervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        {:error, :already_started}

      error ->
        {:error, error}
    end
  end

  def fetch_timer(user_id) do
    case Registry.lookup(@registry_name, user_id) do
      [] ->
        {:error, :not_found}

      [{pid, _}] ->
        {:ok, pid}
    end
  end

  def stop_timer(user_id) do
    with :ok <- Supervisor.terminate_child(__MODULE__, timer_id(user_id)) do
      Supervisor.delete_child(__MODULE__, timer_id(user_id))
    end
  end

  defp timer_id(user_id) do
    {Timer, user_id}
  end

  defp timer_via_tuple(user_id) do
    {:via, Registry, {@registry_name, user_id}}
  end

  defp timer_spec(user_id, timer_opts) do
    opts = Keyword.put(timer_opts, :name, timer_via_tuple(user_id))

    %{
      id: timer_id(user_id),
      start: {Timer, :start_link, [opts]},
      restart: :temporary
    }
  end
end

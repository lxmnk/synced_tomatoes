defmodule SyncedTomatoes.Core.Commands.SyncTimer do
  alias SyncedTomatoes.Core.{Timer, TimerManager}

  def execute(user_id, sync_data) do
    with {:ok, timer} <- TimerManager.fetch_timer(user_id) do
      Timer.sync(timer, sync_data)
    end
  end
end

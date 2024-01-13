defmodule SyncedTomatoes.Core.Commands.PauseTimer do
  alias SyncedTomatoes.Core.{Timer, TimerManager}

  def execute(user_id) do
    with {:ok, timer} <- TimerManager.fetch_timer(user_id) do
      Timer.pause(timer)
    end
  end
end

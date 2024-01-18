defmodule SyncedTomatoes.Core.Commands.PauseTimer do
  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  def execute(user_id) do
    with {:ok, timer} <- TimerSupervisor.fetch_timer(user_id) do
      Timer.pause(timer)
    end
  end
end

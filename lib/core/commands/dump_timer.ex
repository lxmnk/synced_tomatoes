defmodule SyncedTomatoes.Core.Commands.DumpTimer do
  alias SyncedTomatoes.Core.{Timer, TimerDump, TimerManager}
  alias SyncedTomatoes.Repos.Postgres

  def execute(user_id) do
    case TimerManager.fetch_timer(user_id) do
      {:ok, timer} ->
        params =
          timer
          |> Timer.get_status()
          |> map_status()

        %TimerDump{user_id: user_id}
        |> TimerDump.changeset(params)
        |> Postgres.insert(on_conflict: :replace_all, conflict_target: :user_id)

      {:error, :not_found} ->
        :ok
    end
  end

  defp map_status(status) do
    %{
      interval_type: Atom.to_string(status.interval_type),
      current_work_interval: status.current_work_interval,
      time_left_ms: status.time_left_ms
    }
  end
end

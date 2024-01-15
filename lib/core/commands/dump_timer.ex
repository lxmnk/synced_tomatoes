defmodule SyncedTomatoes.Core.Commands.DumpTimer do
  alias SyncedTomatoes.Core.{Timer, TimerDump, TimerManager}
  alias SyncedTomatoes.Repos.Postgres

  def execute(user_id) do
    case TimerManager.fetch_timer(user_id) do
      {:ok, timer} ->
        params =
          timer
          |> Timer.get_status()
          |> Map.delete(:ticking?)
          |> Map.update!(:interval_type, &(Atom.to_string(&1)))

        %TimerDump{user_id: user_id}
        |> TimerDump.changeset(params)
        |> Postgres.insert(on_conflict: :replace_all, conflict_target: :user_id)

      {:error, :not_found} ->
        :ok
    end
  end
end

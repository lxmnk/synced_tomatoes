defmodule SyncedTomatoes.Web.WebSocket.Methods.GetSettings do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Settings
  alias SyncedTomatoes.Repos.Postgres

  @impl true
  def execute(context, _) do
    {:ok, Postgres.get!(Settings, context.user_id)}
  end

  @impl true
  def map_result(result) do
    %{
      "workMin" => result.work_min,
      "shortBreakMin" => result.short_break_min,
      "longBreakMin" => result.long_break_min,
      "workIntervalsCount" => result.work_intervals_count
    }
  end
end

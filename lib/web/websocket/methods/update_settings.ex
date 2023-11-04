defmodule SyncedTomatoes.Web.WebSocket.Methods.UpdateSettings do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.UpdateSettings

  defmodule ParamsSchema do
    use Construct do
      field :workMin, :integer
      field :shortBreakMin, :integer
      field :longBreakMin, :integer
      field :workIntervalsCount, :integer
    end
  end

  def execute(context, params) do
    with :ok <- UpdateSettings.execute(context.user_id, params) do
      {:ok, "Settings updated"}
    end
  end

  def map_params(params) do
    %{
      "work_min" => Map.fetch!(params, "workMin"),
      "short_break_min" => Map.fetch!(params, "shortBreakMin"),
      "long_break_min" => Map.fetch!(params, "longBreakMin"),
      "work_intervals_count" => Map.fetch!(params, "workIntervalsCount")
    }
  end
end

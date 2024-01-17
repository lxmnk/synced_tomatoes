defmodule SyncedTomatoes.Web.WebSocket.Methods.UpdateSettings do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.UpdateSettings
  alias SyncedTomatoes.Core.Types.PositiveInteger

  defmodule UpdateSettingsRequest do
    use Construct do
      field :workMin, PositiveInteger
      field :shortBreakMin, PositiveInteger
      field :longBreakMin, PositiveInteger
      field :workIntervalsCount, PositiveInteger
    end
  end

  @impl true
  def params_schema do
    UpdateSettingsRequest
  end

  @impl true
  def map_params(params) do
    %{
      work_min: params.workMin,
      short_break_min: params.shortBreakMin,
      long_break_min: params.longBreakMin,
      work_intervals_count: params.workIntervalsCount
    }
  end

  @impl true
  def execute(context, params) do
    with :ok <- UpdateSettings.execute(context.user_id, params) do
      {:ok, "Settings updated"}
    end
  end
end

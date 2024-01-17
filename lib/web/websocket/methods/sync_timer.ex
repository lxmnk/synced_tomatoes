defmodule SyncedTomatoes.Web.WebSocket.Methods.SyncTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.SyncTimer
  alias SyncedTomatoes.Core.Types.PositiveInteger

  defmodule SyncTimerRequest do
    defmodule IntervalType do
      @behaviour Construct.Type

      def cast(v) when is_binary(v) and v in ~w(work short_break long_break), do: {:ok, v}
      def cast(_), do: {:error, :invalid}
    end

    use Construct do
      field :intervalType, IntervalType
      field :currentWorkInterval, PositiveInteger
      field :timeLeftMs, PositiveInteger
    end
  end

  @impl true
  def params_schema do
    SyncTimerRequest
  end

  @impl true
  def map_params(params) do
    %{
      interval_type: params.intervalType,
      current_work_interval: params.currentWorkInterval,
      time_left_ms: params.timeLeftMs
    }
  end

  @impl true
  def execute(context, sync_data) do
    case SyncTimer.execute(context.user_id, sync_data) do
      {:error, :not_found} ->
        {:error, "Timer not started"}

      {:error, :timer_ticking} ->
        {:error, "Can't sync ticking timer"}

      result ->
        result
    end
  end
end

defmodule SyncedTomatoes.Web.WebSocket.Methods.SyncTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.SyncTimer
  alias SyncedTomatoes.Core.Types.PositiveInteger
  alias SyncedTomatoes.Web.WebSocket.Methods.GetTimer
  alias SyncedTomatoes.Web.WebSocketRegistry

  defmodule SyncTimerRequest do
    defmodule IntervalType do
      @behaviour Construct.Type

      def cast("work"), do: {:ok, :work}
      def cast("shortBreak"), do: {:ok, :short_break}
      def cast("longBreak"), do: {:ok, :long_break}
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
    with :ok <- SyncTimer.execute(context.user_id, sync_data),
         {:ok, timer_info} <- GetTimer.call(context, %{})
    do
      event = %{event: "timerSynced", payload: timer_info}
      WebSocketRegistry.publish_to_other(context.user_id, context.device_id, event)

      {:ok, timer_info}
    else
      {:error, :not_found} ->
        {:error, "Timer not started"}

      {:error, :timer_ticking} ->
        {:error, "Can't sync ticking timer"}

      error ->
        error
    end
  end
end

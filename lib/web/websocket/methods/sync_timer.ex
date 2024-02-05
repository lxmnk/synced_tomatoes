defmodule SyncedTomatoes.Web.WebSocket.Methods.SyncTimer do
  use SyncedTomatoes.Web.WebSocket.Method

  alias SyncedTomatoes.Core.Commands.SyncTimer
  alias SyncedTomatoes.Core.Types.PositiveInteger
  alias SyncedTomatoes.Web.WebSocket.Methods.GetTimer

  defmodule SyncTimerRequest do
    defmodule IntervalType do
      @behaviour Construct.Type

      def cast(value)
          when is_binary(value) and value in ~w(work shortBreak longBreak)
      do
        {:ok, map(value)}
      end
      def cast(_) do
        {:error, :invalid}
      end

      defp map("work"), do: :work
      defp map("shortBreak"), do: :short_break
      defp map("longBreak"), do: :long_break
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
      :ok ->
        GetTimer.call(context, %{})

      {:error, :not_found} ->
        {:error, "Timer not started"}

      {:error, :timer_ticking} ->
        {:error, "Can't sync ticking timer"}

      error ->
        error
    end
  end
end

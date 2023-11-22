defmodule Test.Web.WebSocket.PauseTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.TimerManager

  setup [:user, :timer_manager]

  describe "common" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerManager.start_timer(context.user.id, settings)

      result = call!(context.token, "pause_timer", %{})

      %{result: result}
    end

    test "return ok", context do
      assert %{
        "id" => _,
        "result" => %{"info" => "Success"}
      } = context.result
    end
  end

  describe "timer not started" do
    setup context do
      result = call!(context.token, "pause_timer", %{})

      %{result: result}
    end

    test "return error", context do
      assert %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Timer not started"
      } = context.result
    end
  end

  describe "timer already paused" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerManager.start_timer(context.user.id, settings)

      {_, timer_pid, _, _} =
        TimerManager
        |> Supervisor.which_children()
        |> Enum.find(
          fn
            {{SyncedTomatoes.Core.Timer, _}, _, _, _} -> true
            _ -> false
          end
        )

      :sys.replace_state(timer_pid, fn state ->
        state
        |> Map.put(:ticking?, false)
      end)

      result = call!(context.token, "pause_timer", %{})

      %{result: result}
    end

    test "return error", context do
      assert %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Already paused"
      } = context.result
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end

  defp timer_manager(_) do
    start_supervised!(TimerManager, restart: :temporary)

    :ok
  end
end

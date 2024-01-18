defmodule Test.Web.WebSocket.TerminateTest do
  use Test.Cases.DBCase

  alias SyncedTomatoes.Core.{TimerDump, TimerSupervisor}
  alias SyncedTomatoes.Web.WebSocket

  describe "common" do
    setup do
      put_env(:websocket_cleanup_enabled?, true)

      user = insert(:user)

      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]
      {:ok, pid} = TimerSupervisor.start_timer(user.id, settings)

      result = WebSocket.terminate(:unused, :unused, %{user_id: user.id})

      %{result: result, user_id: user.id, timer_pid: pid}
    end

    test "returns ok", context do
      assert :ok = context.result
    end

    test "dumps active timer", context do
      assert %{
        current_work_interval: 1,
        interval_type: "work",
        time_left_ms: time_left_ms
      } = Postgres.get(TimerDump, context.user_id)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end

    test "stops active timer", context do
      refute Process.alive?(context.timer_pid)
    end
  end

  describe "no active timer" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "returns ok", context do
      user_id = context.user.id

      assert :ok = WebSocket.terminate(:unused, :unused, %{user_id: user_id})
    end
  end

  describe "not authorized" do
    test "returns ok" do
      assert :ok = WebSocket.terminate(:unused, :unused, %{})
    end
  end
end

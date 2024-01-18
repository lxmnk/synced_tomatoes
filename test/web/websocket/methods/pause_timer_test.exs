defmodule Test.Web.WebSocket.PauseTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  setup :user

  describe "common" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerSupervisor.start_timer(context.user.id, settings)

      result = call!(context.token, "pauseTimer", %{})

      %{result: result}
    end

    test "returns paused timer status", context do
      assert %{
        "id" => _,
        "result" => %{
          "current_work_interval" => 1,
          "interval_type" => "work",
          "state" => "paused",
          "time_left_ms" => time_left_ms
        }
      } = context.result

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "timer not started" do
    setup context do
      result = call!(context.token, "pauseTimer", %{})

      %{result: result}
    end

    test "returns error", context do
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

      {:ok, pid} = TimerSupervisor.start_timer(context.user.id, settings)
      Timer.pause(pid)

      result = call!(context.token, "pauseTimer", %{})

      %{result: result}
    end

    test "returns error", context do
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
end

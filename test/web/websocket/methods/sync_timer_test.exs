defmodule Test.Web.WebSocket.Methods.SyncTimerTest do
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

      {:ok, pid} = TimerSupervisor.start_timer(context.user.id, settings)
      Timer.pause(pid)

      params = %{
        intervalType: "longBreak",
        currentWorkInterval: 2,
        timeLeftMs: :timer.minutes(8)
      }
      result = call!(context.token, "syncTimer", params)

      %{result: result, timer_pid: pid}
    end

    test "returns synced timer status", context do
      assert %{
        "id" => _,
        "result" => %{
          "state" => "paused",
          "currentWorkInterval" => 2,
          "intervalType" => "long_break",
          "timeLeftMs" => time_left_ms
        }
      } = context.result

      assert_in_delta :timer.minutes(8), time_left_ms, 100
    end
  end

  describe "timer is ticking" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerSupervisor.start_timer(context.user.id, settings)

      params = %{
        intervalType: "longBreak",
        currentWorkInterval: 2,
        timeLeftMs: :timer.minutes(8)
      }
      result = call!(context.token, "syncTimer", params)

      %{result: result}
    end

    test "returns error", context do
      assert %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Can't sync ticking timer"
      } = context.result
    end
  end

  describe "timer not started" do
    setup context do
      params = %{
        intervalType: "longBreak",
        currentWorkInterval: 2,
        timeLeftMs: :timer.minutes(8)
      }
      result = call!(context.token, "syncTimer", params)

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

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

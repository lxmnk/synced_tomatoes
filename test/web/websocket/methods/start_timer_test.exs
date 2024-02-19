defmodule Test.Web.WebSocket.Methods.StartTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  setup :user

  describe "common" do
    setup context do
      {:ok, result} = rpc_call(context.token, "startTimer", %{})

      %{result: result}
    end

    test "returns started timer status", context do
      assert %{
        "id" => _,
        "result" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "currentWorkInterval" => 1,
          "timeLeftMs" => time_left_ms
        }
      } = context.result

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "continue timer" do
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

      {:ok, result} = rpc_call(context.token, "startTimer", %{})

      %{result: result, pid: pid}
    end

    test "returns continued timer status", context do
      assert %{
        "id" => _,
        "result" => %{
          "currentWorkInterval" => 1,
          "intervalType" => "work",
          "state" => "ticking",
          "timeLeftMs" => time_left_ms
        }
      } = context.result

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "start timer when timer dump exists" do
    setup context do
      insert(:timer_dump,
        interval_type: "long_break",
        current_work_interval: 2,
        time_left_ms: :timer.minutes(8),
        user_id: context.user.id
      )

      {:ok, result} = rpc_call(context.token, "startTimer", %{})

      %{result: result}
    end

    test "returns started timer status", context do
      assert %{
        "id" => _,
        "result" => %{
          "currentWorkInterval" => 2,
          "intervalType" => "long_break",
          "state" => "ticking",
          "timeLeftMs" => time_left_ms
        }
      } = context.result

      assert_in_delta :timer.minutes(8), time_left_ms, 100
    end
  end

  describe "timer already ticking" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerSupervisor.start_timer(context.user.id, settings)

      {:ok, result} = rpc_call(context.token, "startTimer", %{})

      %{result: result}
    end

    test "returns error", context do
      assert %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Already ticking"
      } = context.result
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

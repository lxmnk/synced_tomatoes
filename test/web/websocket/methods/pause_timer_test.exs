defmodule Test.Web.WebSocket.Methods.PauseTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  describe "common" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerSupervisor.start_timer(user.id, settings)

      {:ok, wsc_pid} = rpc_call(token, "pauseTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns paused timer status", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "currentWorkInterval" => 1,
          "intervalType" => "work",
          "state" => "paused",
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "timer not started" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      {:ok, wsc_pid} = rpc_call(token, "pauseTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns error", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Timer not started"
      }}
    end
  end

  describe "timer already paused" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, timer_pid} = TimerSupervisor.start_timer(user.id, settings)
      Timer.pause(timer_pid)

      {:ok, wsc_pid} = rpc_call(token, "pauseTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns error", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Already paused"
      }}
    end
  end
end

defmodule Test.Web.WebSocket.Methods.SyncTimerTest do
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

      {:ok, timer_pid} = TimerSupervisor.start_timer(user.id, settings)
      Timer.pause(timer_pid)

      params = %{
        intervalType: "longBreak",
        currentWorkInterval: 2,
        timeLeftMs: :timer.minutes(8)
      }
      {:ok, wsc_pid} = rpc_call(token, "syncTimer", params)

      %{wsc_pid: wsc_pid, timer_pid: timer_pid}
    end

    test "returns synced timer status", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "state" => "paused",
          "currentWorkInterval" => 2,
          "intervalType" => "long_break",
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(8), time_left_ms, 100
    end
  end

  describe "timer is ticking" do
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

      params = %{
        intervalType: "longBreak",
        currentWorkInterval: 2,
        timeLeftMs: :timer.minutes(8)
      }
      {:ok, wsc_pid} = rpc_call(token, "syncTimer", params)

      %{wsc_pid: wsc_pid}
    end

    test "returns error", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Can't sync ticking timer"
      }}
    end
  end

  describe "timer not started" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      params = %{
        intervalType: "longBreak",
        currentWorkInterval: 2,
        timeLeftMs: :timer.minutes(8)
      }
      {:ok, wsc_pid} = rpc_call(token, "syncTimer", params)

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
end

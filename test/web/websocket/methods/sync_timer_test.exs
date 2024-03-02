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
          "intervalType" => "longBreak",
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(8), time_left_ms, 100
    end
  end

  describe "two websockets" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)
      %{value: token2} = insert(:token, user: user)

      {:ok, wsc_pid1} = WSClient.start_link(token: token)
      :ok = WSClient.connect(wsc_pid1)
      {:ok, wsc_pid2} = WSClient.start_link(token: token2)
      :ok = WSClient.connect(wsc_pid2)

      :ok = WSClient.send_text(wsc_pid1, build_rpc("startTimer", %{}))
      assert_receive {{WSClient, ^wsc_pid1}, %{"id" => _, "result" => %{}}}

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(user.id)
      Timer.pause(timer_pid)

      params = %{
        intervalType: "longBreak",
        currentWorkInterval: 2,
        timeLeftMs: :timer.minutes(8)
      }
      :ok = WSClient.send_text(wsc_pid1, build_rpc("syncTimer", params))

      %{wsc_pid1: wsc_pid1, wsc_pid2: wsc_pid2}
    end

    test "returns synced timer status", %{wsc_pid1: wsc_pid1} do
      assert_receive {{WSClient, ^wsc_pid1}, %{
        "id" => _,
        "result" => %{
          "state" => "paused",
          "intervalType" => "longBreak",
          "currentWorkInterval" => 2,
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(8), time_left_ms, 100
    end

    test "first websocket doesn't receive event", %{wsc_pid1: wsc_pid1} do
      refute_receive {{WSClient, ^wsc_pid1}, %{
        "event" => "timerSynced",
        "payload" => %{
          "state" => "paused",
          "intervalType" => "longBreak",
          "currentWorkInterval" => 2,
          "timeLeftMs" => _
        }
      }}
    end

    test "second websocket receives event", %{wsc_pid2: wsc_pid2} do
      assert_receive {{WSClient, ^wsc_pid2}, %{
        "event" => "timerSynced",
        "payload" => %{
          "state" => "paused",
          "intervalType" => "longBreak",
          "currentWorkInterval" => 2,
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

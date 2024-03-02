defmodule Test.Web.WebSocket.Methods.StartTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  describe "common" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      {:ok, wsc_pid} = rpc_call(token, "startTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns started timer status", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "currentWorkInterval" => 1,
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(25), time_left_ms, 100
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

      %{wsc_pid1: wsc_pid1, wsc_pid2: wsc_pid2}
    end

    test "returns started timer status", %{wsc_pid1: wsc_pid1} do
      assert_receive {{WSClient, ^wsc_pid1}, %{
        "id" => _,
        "result" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "currentWorkInterval" => 1,
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end

    test "first websocket doesn't receive event", %{wsc_pid1: wsc_pid1} do
      refute_receive {{WSClient, ^wsc_pid1}, %{
        "event" => "timerStarted",
        "payload" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "currentWorkInterval" => 1,
          "timeLeftMs" => _
        }
      }}
    end

    test "second websocket receives event", %{wsc_pid2: wsc_pid2} do
      assert_receive {{WSClient, ^wsc_pid2}, %{
        "event" => "timerStarted",
        "payload" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "currentWorkInterval" => 1,
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "continue timer" do
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

      {:ok, wsc_pid} = rpc_call(token, "startTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns continued timer status", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "currentWorkInterval" => 1,
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "start timer when timer dump exists" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      insert(:timer_dump,
        interval_type: "long_break",
        current_work_interval: 2,
        time_left_ms: :timer.minutes(8),
        user_id: user.id
      )

      {:ok, wsc_pid} = rpc_call(token, "startTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns started timer status", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "state" => "ticking",
          "intervalType" => "long_break",
          "currentWorkInterval" => 2,
          "timeLeftMs" => time_left_ms
        }
      }}

      assert_in_delta :timer.minutes(8), time_left_ms, 100
    end
  end

  describe "timer already ticking" do
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

      {:ok, wsc_pid} = rpc_call(token, "startTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns error", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Already ticking"
      }}
    end
  end
end

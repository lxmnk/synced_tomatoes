defmodule Test.Web.WebSocket.Events.LongBreakFinishedTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  describe "common" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      {:ok, wsc_pid} = rpc_call(token, "startTimer")
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{"state" => "ticking"}
      }}

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(user.id)
      Timer.pause(timer_pid)
      Timer.sync(timer_pid, %{
        interval_type: :long_break,
        current_work_interval: 1,
        time_left_ms: 1
      })
      Timer.continue(timer_pid)

      %{wsc_pid: wsc_pid}
    end

    test "receives event", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "event" => "long_break_finished",
        "payload" => %{}
      }}
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
      assert_receive {{WSClient, ^wsc_pid1}, %{
        "id" => _,
        "result" => %{"state" => "ticking"}
      }}

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(user.id)
      Timer.pause(timer_pid)
      Timer.sync(timer_pid, %{
        interval_type: :long_break,
        current_work_interval: 1,
        time_left_ms: 1
      })
      Timer.continue(timer_pid)

      %{wsc_pid1: wsc_pid1, wsc_pid2: wsc_pid2}
    end

    test "first websocket receives event", %{wsc_pid1: wsc_pid1} do
      assert_receive {{WSClient, ^wsc_pid1}, %{
        "event" => "long_break_finished",
        "payload" => %{}
      }}
    end

    test "second websocket receives event", %{wsc_pid2: wsc_pid2} do
      assert_receive {{WSClient, ^wsc_pid2}, %{
        "event" => "long_break_finished",
        "payload" => %{}
      }}
    end
  end
end

defmodule Test.Web.WebSocket.Methods.GetTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.TimerSupervisor

  describe "timer not started" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      {:ok, wsc_pid} = rpc_call(token, "getTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns default timer", %{wsc_pid: wsc_pid} do
      time_left_ms = :timer.minutes(25)

      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "state" => "stopped",
          "intervalType" => "work",
          "timeLeftMs" => ^time_left_ms,
          "currentWorkInterval" => 1
        }
      }}
    end
  end

  describe "timer started" do
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

      {:ok, wsc_pid} = rpc_call(token, "getTimer")

      %{wsc_pid: wsc_pid}
    end

    test "returns timer", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "timeLeftMs" => time_left_ms,
          "currentWorkInterval" => 1
        }
      }}

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end
end

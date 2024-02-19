defmodule Test.Web.WebSocket.Methods.GetTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.TimerSupervisor

  setup :user

  describe "timer not started" do
    setup context do
      {:ok, result} = rpc_call(context.token, "getTimer", %{})

      %{result: result}
    end

    test "returns default timer", context do
      time_left_ms = :timer.minutes(25)

      assert %{
        "id" => _,
        "result" => %{
          "state" => "stopped",
          "intervalType" => "work",
          "timeLeftMs" => ^time_left_ms,
          "currentWorkInterval" => 1
        }
      } = context.result
    end
  end

  describe "timer started" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerSupervisor.start_timer(context.user.id, settings)

      {:ok, result} = rpc_call(context.token, "getTimer", %{})

      %{result: result}
    end

    test "returns timer", context do
      assert %{
        "id" => _,
        "result" => %{
          "state" => "ticking",
          "intervalType" => "work",
          "timeLeftMs" => time_left_ms,
          "currentWorkInterval" => 1
        }
      } = context.result

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

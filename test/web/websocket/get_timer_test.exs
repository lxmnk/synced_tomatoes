defmodule Test.Web.WebSocket.GetTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.TimerManager

  setup [:user, :timer_manager]

  describe "timer not started" do
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
      } = call!(context.token, "getTimer", %{})
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

      TimerManager.start_timer(context.user.id, settings)

      :ok
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
      } = call!(context.token, "getTimer", %{})

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end

  defp timer_manager(_) do
    start_supervised!(TimerManager, restart: :temporary)

    :ok
  end
end

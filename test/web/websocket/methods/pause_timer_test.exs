defmodule Test.Web.WebSocket.PauseTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.TimerManager

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

      TimerManager.start_timer(context.user.id, settings)

      result = call!(context.token, "pauseTimer", %{})

      %{result: result}
    end

    test "returns ok", context do
      assert %{
        "id" => _,
        "result" => %{"info" => "Success"}
      } = context.result
    end
  end

  describe "timer not started" do
    setup context do
      result = call!(context.token, "pauseTimer", %{})

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

  describe "timer already paused" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = TimerManager.start_timer(context.user.id, settings)
      :sys.replace_state(pid, fn state ->
        state
        |> Map.put(:ticking?, false)
        |> Map.put(:saved_timer_value, 1000)
      end)

      result = call!(context.token, "pauseTimer", %{})

      %{result: result}
    end

    test "returns error", context do
      assert %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Already paused"
      } = context.result
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

defmodule Test.Web.WebSocket.StartTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerManager}

  setup :user

  describe "common" do
    setup context do
      result = call!(context.token, "startTimer", %{})

      %{result: result}
    end

    test "returns ok", context do
      assert %{
        "id" => _,
        "result" => %{"info" => "Success"}
      } = context.result
    end

    test "starts new timer", context do
      assert {:ok, _ } = TimerManager.fetch_timer(context.user.id)
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

      {:ok, pid} = TimerManager.start_timer(context.user.id, settings)
      Timer.pause(pid)

      result = call!(context.token, "startTimer", %{})

      %{result: result, pid: pid}
    end

    test "returns ok", context do
      assert %{
        "id" => _,
        "result" => %{"info" => "Success"}
      } = context.result
    end

    test "continues timer", context do
      %{ticking?: true} = Timer.get_status(context.pid)
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

      result = call!(context.token, "startTimer", %{})

      %{result: result}
    end

    test "returns ok", context do
      assert %{
        "id" => _,
        "result" => %{"info" => "Success"}
      } = context.result
    end

    test "starts new timer from dump", context do
      assert {:ok, pid} = TimerManager.fetch_timer(context.user.id)

      assert %{
        interval_type: "long_break",
        current_work_interval: 2,
        time_left_ms: time_left_ms
      } = Timer.get_status(pid)

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

      TimerManager.start_timer(context.user.id, settings)

      result = call!(context.token, "startTimer", %{})

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

defmodule Test.Web.WebSocket.StartTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerManager}

  setup [:user, :timer_manager]

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

    test "starts new timer" do
      assert [_, _] = Supervisor.which_children(TimerManager)
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
      :sys.replace_state(pid, fn state ->
        state
        |> Map.put(:ticking?, false)
        |> Map.put(:saved_timer_value, 1000)
      end)

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

  defp timer_manager(_) do
    start_supervised!(TimerManager, restart: :temporary)

    :ok
  end
end

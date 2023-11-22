defmodule Test.Web.WebSocket.StartTimerTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.TimerManager

  setup [:user, :timer_manager]

  describe "common" do
    setup context do
      result = call!(context.token, "start_timer", %{})

      %{result: result}
    end

    test "return ok", context do
      assert %{
        "id" => _,
        "result" => %{"info" => "Success"}
      } = context.result
    end

    test "starts new timer" do
      assert [_, _] = Supervisor.which_children(TimerManager)
    end
  end

  describe "timer already started" do
    setup context do
      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      TimerManager.start_timer(context.user.id, settings)

      result = call!(context.token, "start_timer", %{})

      %{result: result}
    end

    test "return error", context do
      assert %{
        "id" => _,
        "error" => "Method call error",
        "reason" => "Already started"
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

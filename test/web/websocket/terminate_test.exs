defmodule Test.Web.WebSocket.TerminateTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{TimerDump, TimerSupervisor}
  alias SyncedTomatoes.Web.WebSocket

  describe "common" do
    setup :user

    setup context do
      put_env(:websocket_cleanup_enabled?, true)

      {:ok, pid} = Test.WebSocketClient.start_link(token: context.token)
      :ok = Test.WebSocketClient.connect(pid)
      {:ok, _} = rpc_call(pid, "startTimer", %{})

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(context.user.id)

      result = WebSocket.terminate(
        :unused,
        :unused,
        %{user_id: context.user.id, device_id: context.device_id}
      )

      :ok = Test.WebSocketClient.disconnect(pid)

      %{result: result, timer_pid: timer_pid}
    end

    test "returns ok", context do
      assert :ok = context.result
    end

    test "dumps active timer", context do
      assert %{
        current_work_interval: 1,
        interval_type: "work",
        time_left_ms: time_left_ms
      } = Postgres.get(TimerDump, context.user.id)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end

    test "stops active timer", context do
      refute Process.alive?(context.timer_pid)
    end
  end

  describe "no active timer" do
    setup :user

    setup context do
      put_env(:websocket_cleanup_enabled?, true)

      {:ok, pid} = Test.WebSocketClient.start_link(token: context.token)
      :ok = Test.WebSocketClient.connect(pid)

      result = WebSocket.terminate(
        :unused,
        :unused,
        %{user_id: context.user.id, device_id: context.device_id}
      )

      :ok = Test.WebSocketClient.disconnect(pid)

      %{result: result}
    end

    test "returns ok", context do
      assert :ok = context.result
    end
  end

  describe "not authorized" do
    test "returns ok" do
      assert :ok = WebSocket.terminate(:unused, :unused, %{})
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, device_id: token.device_id, token: token.value}
  end
end

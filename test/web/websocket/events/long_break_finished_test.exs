defmodule Test.Web.WebSocket.Events.LongBreakFinishedTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  setup :user

  describe "common" do
    setup context do
      {:ok, pid} = Test.WebSocketClient.start_link(token: context.token)
      :ok = Test.WebSocketClient.connect(pid)
      {:ok, _} = rpc_call(pid, "startTimer", %{})

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(context.user.id)
      Timer.pause(timer_pid)
      Timer.sync(timer_pid, %{
        interval_type: :long_break,
        current_work_interval: 1,
        time_left_ms: 1
      })
      Timer.continue(timer_pid)

      {:ok, event} = rpc_event(pid)

      :ok = Test.WebSocketClient.disconnect(pid)

      %{event: event}
    end

    test "receives event", context do
      assert %{
        "event" => "long_break_finished",
        "payload" => %{}
      } = context.event
    end
  end

  describe "two websockets" do
    setup context do
      %{value: token2} = insert(:token, user: context.user)

      {:ok, pid1} = Test.WebSocketClient.start_link(token: context.token)
      :ok = Test.WebSocketClient.connect(pid1)
      {:ok, pid2} = Test.WebSocketClient.start_link(token: token2)
      :ok = Test.WebSocketClient.connect(pid2)

      {:ok, _} = rpc_call(pid1, "startTimer", %{})

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(context.user.id)
      Timer.pause(timer_pid)
      Timer.sync(timer_pid, %{
        interval_type: :long_break,
        current_work_interval: 1,
        time_left_ms: 1
      })
      Timer.continue(timer_pid)

      test_pid = self()
      spawn(fn ->
        {:ok, event} = rpc_event(pid1)
        send(test_pid, {:event1, event})
      end)
      spawn(fn ->
        {:ok, event} = rpc_event(pid2)
        send(test_pid, {:event2, event})
      end)
      Process.sleep(100)

      :ok = Test.WebSocketClient.disconnect(pid1)
      :ok = Test.WebSocketClient.disconnect(pid2)

      :ok
    end

    test "first websocket receives event" do
      assert_received {
        :event1,
        %{
          "event" => "long_break_finished",
          "payload" => %{}
        }
      }
    end

    test "second websocket receives event" do
      assert_received {
        :event2,
        %{
          "event" => "long_break_finished",
          "payload" => %{}
        }
      }
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

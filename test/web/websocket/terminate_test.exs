defmodule Test.Web.WebSocket.TerminateTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{TimerDump, TimerSupervisor}
  alias SyncedTomatoes.Web.WebSocket
  alias SyncedTomatoes.Web.WebSocketRegistry

  describe "common" do
    setup do
      put_env(:websocket_cleanup_enabled?, true)

      user = insert(:user)
      %{value: token, device_id: device_id} = insert(:token, user: user)

      {:ok, wsc_pid} = WSClient.start_link(token: token)
      :ok = WSClient.connect(wsc_pid)

      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]
      {:ok, timer_pid} = TimerSupervisor.start_timer(user.id, settings)
      WebSocketRegistry.add(user.id, device_id)

      result = WebSocket.terminate(
        :unused,
        :unused,
        %{user_id: user.id, device_id: device_id}
      )

      %{result: result, user_id: user.id, timer_pid: timer_pid}
    end

    test "returns ok", context do
      assert :ok = context.result
    end

    test "dumps active timer", context do
      assert %{
        current_work_interval: 1,
        interval_type: "work",
        time_left_ms: time_left_ms
      } = Postgres.get(TimerDump, context.user_id)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end

    test "stops active timer", context do
      refute Process.alive?(context.timer_pid)
    end
  end

  describe "two websockets" do
    setup do
      put_env(:websocket_cleanup_enabled?, true)

      user = insert(:user)
      %{value: token, device_id: device_id} = insert(:token, user: user)
      %{value: token2, device_id: device_id2} = insert(:token, user: user)

      {:ok, wsc_pid1} = WSClient.start_link(token: token)
      :ok = WSClient.connect(wsc_pid1)
      {:ok, wsc_pid2} = WSClient.start_link(token: token2)
      :ok = WSClient.connect(wsc_pid2)

      settings = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]
      {:ok, timer_pid} = TimerSupervisor.start_timer(user.id, settings)
      WebSocketRegistry.add(user.id, device_id)
      WebSocketRegistry.add(user.id, device_id2)

      result = WebSocket.terminate(
        :unused,
        :unused,
        %{user_id: user.id, device_id: device_id}
      )

      %{result: result, user_id: user.id, timer_pid: timer_pid}
    end

    test "returns ok", context do
      assert :ok = context.result
    end

    test "doesn't dump timer", context do
      refute Postgres.get(TimerDump, context.user_id)
    end

    test "doesn't stop timer", context do
      assert Process.alive?(context.timer_pid)
    end
  end

  describe "no active timer" do
    setup do
      put_env(:websocket_cleanup_enabled?, true)

      user = insert(:user)
      %{value: token, device_id: device_id} = insert(:token, user: user)

      {:ok, wsc_pid} = WSClient.start_link(token: token)
      :ok = WSClient.connect(wsc_pid)

      result = WebSocket.terminate(
        :unused,
        :unused,
        %{user_id: user.id, device_id: device_id}
      )

      :ok = WSClient.disconnect(wsc_pid)

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
end

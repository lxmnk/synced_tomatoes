defmodule Test.Web.WebSocket.TerminateTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{TimerDump, TimerSupervisor}
  alias SyncedTomatoes.Web.WebSocket

  describe "common" do
    setup do
      put_env(:websocket_cleanup_enabled?, true)

      user = insert(:user)
      %{value: token, device_id: device_id} = insert(:token, user: user)

      {:ok, wsc_pid} = WSClient.start_link(token: token)
      :ok = WSClient.connect(wsc_pid)
      :ok = WSClient.send_text(wsc_pid, build_rpc("startTimer", %{}))
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{"state" => "ticking"}
      }}

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(user.id)

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
      %{value: token2} = insert(:token, user: user)

      {:ok, wsc_pid1} = WSClient.start_link(token: token)
      :ok = WSClient.connect(wsc_pid1)
      {:ok, wsc_pid2} = WSClient.start_link(token: token2)
      :ok = WSClient.connect(wsc_pid2)

      :ok = WSClient.send_text(wsc_pid1, build_rpc("startTimer", %{}))
      assert_receive {{WSClient, ^wsc_pid1}, %{
        "id" => _,
        "result" => %{"state" => "ticking"}
      }}

      {:ok, timer_pid} = TimerSupervisor.fetch_timer(user.id)

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

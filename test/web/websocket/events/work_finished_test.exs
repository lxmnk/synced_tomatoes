defmodule Test.Web.WebSocket.Events.WorkFinishedTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.{Timer, TimerSupervisor}

  setup :user

  describe "common" do
    setup context do
      {:ok, ws_connection} = open_websocket(context.token)

      call!(ws_connection, "startTimer", %{})

      {:ok, pid} = TimerSupervisor.fetch_timer(context.user.id)
      Timer.pause(pid)
      Timer.sync(pid, %{
        interval_type: :work,
        current_work_interval: 1,
        time_left_ms: 1
      })
      Timer.continue(pid)

      event = receive_event!(ws_connection)

      on_exit(fn -> close_websocket(ws_connection) end)

      %{event: event}
    end

    test "receives event", context do
      assert %{
        "event" => "work_finished",
        "payload" => %{}
      } = context.event
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

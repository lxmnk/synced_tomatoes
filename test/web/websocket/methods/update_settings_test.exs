defmodule Test.Web.WebSocket.Methods.UpdateSettingsTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.Settings
  alias SyncedTomatoes.Repos.Postgres

  describe "common" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      {:ok, wsc_pid} = rpc_call(token, "updateSettings", %{
        "workMin" => 24,
        "shortBreakMin" => 4,
        "longBreakMin" => 14,
        "workIntervalsCount" => 3
      })

      %{wsc_pid: wsc_pid, user_id: user.id}
    end

    test "returns ok", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => "Settings updated"
      }}
    end

    test "updates settings", context do
      wsc_pid = context.wsc_pid
      assert_receive {{WSClient, ^wsc_pid}, %{"id" => _, "result" => _}}

      assert %{
        work_min: 24,
        short_break_min: 4,
        long_break_min: 14,
        work_intervals_count: 3
      } = Postgres.get_by(Settings, user_id: context.user_id)
    end
  end

  describe "negative work_min" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      {:ok, wsc_pid} = rpc_call(token, "updateSettings", %{
        "workMin" => -1,
        "shortBreakMin" => 4,
        "longBreakMin" => 14,
        "workIntervalsCount" => 3
      })

      %{wsc_pid: wsc_pid, user_id: user.id}
    end

    test "returns error", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "error" => "Method call error",
        "reason" => %{"workMin" => "not_a_positive_integer"}
      }}
    end
  end
end

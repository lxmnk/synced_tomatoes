defmodule Test.Web.WebSocket.Methods.UpdateSettingsTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.Settings
  alias SyncedTomatoes.Repos.Postgres

  setup :user

  describe "common" do
    setup context do
      {:ok, result} = rpc_call(context.token, "updateSettings", %{
        "workMin" => 24,
        "shortBreakMin" => 4,
        "longBreakMin" => 14,
        "workIntervalsCount" => 3
      })

      %{user_id: context.user.id, result: result}
    end

    test "returns ok", context do
      assert %{
        "id" => _,
        "result" => "Settings updated"
      } = context.result
    end

    test "updates settings", context do
      assert %{
        work_min: 24,
        short_break_min: 4,
        long_break_min: 14,
        work_intervals_count: 3
      } = Postgres.get_by(Settings, user_id: context.user_id)
    end
  end

  describe "negative work_min" do
    setup context do
      {:ok, result} = rpc_call(context.token, "updateSettings", %{
        "workMin" => -1,
        "shortBreakMin" => 4,
        "longBreakMin" => 14,
        "workIntervalsCount" => 3
      })

      %{user_id: context.user.id, result: result}
    end

    test "returns error", context do
      assert %{
        "id" => _,
        "error" => "Method call error",
        "reason" => %{"workMin" => "not_a_positive_integer"}
      } = context.result
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

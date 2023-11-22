defmodule Test.Web.WebSocket.UpdateSettingsTest do
  use Test.Cases.WSCase

  alias SyncedTomatoes.Core.Settings
  alias SyncedTomatoes.Repos.Postgres

  setup :user

  describe "common" do
    setup context do
      result = call!(context.token, "update_settings", %{
        "workMin" => 24,
        "shortBreakMin" => 4,
        "longBreakMin" => 14,
        "workIntervalsCount" => 3
      })

      %{user_id: context.user.id, result: result}
    end

    test "returns success", context do
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

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

defmodule Test.Web.WebSocket.Methods.GetSettingsTest do
  use Test.Cases.WSCase

  setup :user

  describe "common" do
    test "returns timer settings", context do
      assert %{
        "id" => _,
        "result" => %{
          "workMin" => 25,
          "shortBreakMin" => 5,
          "longBreakMin" => 15,
          "workIntervalsCount" => 4
        }
      } = call!(context.token, "getSettings", %{})
    end
  end

  defp user(_) do
    user = insert(:user)
    token = insert(:token, user: user)

    %{user: user, token: token.value}
  end
end

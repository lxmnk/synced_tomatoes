defmodule Test.Web.WebSocket.Methods.GetSettingsTest do
  use Test.Cases.WSCase

  describe "common" do
    setup do
      user = insert(:user)
      %{value: token} = insert(:token, user: user)

      {:ok, wsc_pid} = rpc_call(token, "getSettings")

      %{wsc_pid: wsc_pid}
    end

    test "returns timer settings", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => _,
        "result" => %{
          "workMin" => 25,
          "shortBreakMin" => 5,
          "longBreakMin" => 15,
          "workIntervalsCount" => 4
        }
      }}
    end
  end
end

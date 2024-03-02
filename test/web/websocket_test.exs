defmodule Test.Web.WebSocketTest do
  use Test.Cases.WSCase

  describe "not authenticated" do
    setup do
      {:ok, wsc_pid} = ws_send("invalid_token", "{}")

      %{wsc_pid: wsc_pid}
    end

    test "closes connection", %{wsc_pid: wsc_pid} do
      refute_receive {{WSClient, ^wsc_pid}, _}
    end
  end

  describe "invalid json" do
    setup do
      %{value: token} = insert(:token, user: build(:user))

      {:ok, wsc_pid} = ws_send(token, ~s|{"invalid": "json|)

      %{wsc_pid: wsc_pid}
    end

    test "returns error", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => nil,
        "error" => "Request validation error",
        "reason" => "EOF while parsing" <> _
      }}
    end
  end

  describe "invalid request" do
    setup do
      %{value: token} = insert(:token, user: build(:user))

      request = Jsonrs.encode!(%{method: "missing", params: %{}})

      {:ok, wsc_pid} = ws_send(token, request)

      %{wsc_pid: wsc_pid}
    end

    test "returns error", %{wsc_pid: wsc_pid} do
      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => nil,
        "error" => "Request validation error",
        "reason" => %{"id" => "missing"}
      }}
    end
  end

  describe "method not found" do
    setup do
      %{value: token} = insert(:token, user: build(:user))

      id = UUID4.generate()
      request = Jsonrs.encode!(%{id: id, method: "missing", params: %{}})

      {:ok, wsc_pid} = ws_send(token, request)

      %{wsc_pid: wsc_pid, request_id: id}
    end

    test "returns error", context do
      wsc_pid = context.wsc_pid
      id = context.request_id

      assert_receive {{WSClient, ^wsc_pid}, %{
        "id" => ^id,
        "error" => "Method call error",
        "reason" => "Method not found"
      }}
    end
  end
end

defmodule Test.Web.WebSocketTest do
  use Test.Cases.WSCase

  describe "not authenticated" do
    test "closes websocket" do
      assert {
        :error, {:close, 1008, "Invalid credentials"}
      } = raw_call(nil, Jsonrs.encode!(%{}))
    end
  end

  describe "invalid json" do
    setup :user_auth

    test "returns error", context do
      assert {:ok, response} = raw_call(context.token, ~s|{"invalid": "json|)

      assert %{
        "id" => nil,
        "error" => "Request validation error",
        "reason" => "EOF while parsing" <> _
      } = Jsonrs.decode!(response)
    end
  end

  describe "invalid request" do
    setup :user_auth

    test "returns error", context do
      request = Jsonrs.encode!(%{method: "missing", params: %{}})
      assert {:ok, response} = raw_call(context.token, request)

      assert %{
        "id" => nil,
        "error" => "Request validation error",
        "reason" => "%{id: :missing}"
      } = Jsonrs.decode!(response)
    end
  end

  describe "method not found" do
    setup :user_auth

    test "returns error", context do
      id = UUID4.generate()

      request = Jsonrs.encode!(%{id: id, method: "missing", params: %{}})
      assert {:ok, response} = raw_call(context.token, request)

      assert %{
        "id" => ^id,
        "error" => "Method call error",
        "reason" => "Method not found"
      } = Jsonrs.decode!(response)
    end
  end

  defp user_auth(_) do
    token = insert(:token, user: build(:user))

    %{token: token.value}
  end
end

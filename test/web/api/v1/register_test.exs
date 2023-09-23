defmodule Test.Web.API.V1.RegisterTest do
  use Test.Cases.APICase

  describe "common" do
    setup do
      response = post("/api/v1/register", %{"login" => "login"})

      %{response: response}
    end

    test "register", context do
      json =
        context.response
        |> ensure_status_code!(200)
        |> extract_json!()

      assert %{
        "status" => "ok",
        "result" => "User created"
      } = json
    end
  end

  describe "invalid request" do
    setup do
      response = post("/api/v1/register")

      %{response: response}
    end

    test "register", context do
      json =
        context.response
        |> ensure_status_code!(400)
        |> extract_json!()

      assert %{
        "status" => "error",
        "reason" => %{"login" => "missing"}
      } = json
    end
  end
end

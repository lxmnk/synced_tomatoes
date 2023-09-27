defmodule Test.Web.API.V1.RegisterTest do
  use Test.Cases.APICase

  alias SyncedTomatoes.Core.User
  alias SyncedTomatoes.Repos.Postgres

  describe "common" do
    setup do
      %{login: login} = build(:user)

      response = post("/api/v1/register", %{"login" => login})

      %{login: login, response: response}
    end

    test "returns ok", context do
      json =
        context.response
        |> ensure_status_code!(200)
        |> extract_json!()

      assert %{
        "status" => "ok",
        "result" => "User created"
      } = json
    end

    test "creates user", context do
      assert Postgres.get_by(User, login: context.login)
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

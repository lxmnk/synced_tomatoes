defmodule Test.Web.API.V1.RegisterTest do
  use Test.Cases.APICase

  alias SyncedTomatoes.Core.{Settings, User}
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
        "info" => "User created",
        "result" => %{"token" => token}
      } = json

      assert String.length(token) == 64
    end

    test "creates user and settings", context do
      assert user = Postgres.get_by(User, login: context.login)

      assert Postgres.get_by(Settings, user_id: user.id)
    end
  end

  describe "with existing login" do
    setup do
      %{login: login} = insert(:user)

      response = post("/api/v1/register", %{"login" => login})

      %{login: login, response: response}
    end

    test "returns error", context do
      login = context.login

      json =
        context.response
        |> ensure_status_code!(400)
        |> extract_json!()

      assert %{
        "status" => "error",
        "context" => %{"login" => ^login},
        "reason" => "Login already exists"
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

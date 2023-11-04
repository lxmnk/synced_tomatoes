defmodule SyncedTomatoes.Web.API.V1.Register do
  use SyncedTomatoes.Web.Endpoint

  alias SyncedTomatoes.Core.Commands.CreateUserToken
  alias SyncedTomatoes.Core.Commands.RegisterUser

  defmodule RequestSchema do
    use Construct do
      field :login, :string
    end
  end

  endpoint fn _conn, payload ->
    with {:ok, %{id: user_id}} <- RegisterUser.execute(payload.login),
      {:ok, %{value: token}} <- CreateUserToken.execute(user_id)
    do
      %Ok{result: %{token: token}, info: "User created"}
    else
      {:error, :login_already_exists} ->
        %Error{reason: "Login already exists", context: %{login: payload.login}}

      {:error, reason} ->
        %Error{status_code: 503, reason: inspect(reason)}
    end
  end
end

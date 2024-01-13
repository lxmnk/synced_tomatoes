defmodule SyncedTomatoes.Web.API.V1.Register do
  use SyncedTomatoes.Web.Endpoint

  alias SyncedTomatoes.Core.Commands.CreateToken
  alias SyncedTomatoes.Core.Commands.RegisterUser

  defmodule RegisterRequest do
    use Construct do
      field :login, :string
    end
  end

  @impl true
  def request_schema do
    RegisterRequest
  end

  @impl true
  def execute(_conn, payload) do
    with {:ok, %{id: user_id}} <- RegisterUser.execute(payload.login),
      {:ok, %{value: token}} <- CreateToken.execute(user_id)
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

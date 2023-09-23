defmodule SyncedTomatoes.Web.API.V1.Register do
  use SyncedTomatoes.Web.Endpoint

  alias SyncedTomatoes.Core.Commands.RegisterUser

  defmodule RequestSchema do
    use Construct do
      field :login, :string
    end
  end

  endpoint fn _conn, payload ->
    with {:ok, _} <- RegisterUser.execute(payload.login) do
      %Ok{result: "User created"}
    end
  end
end

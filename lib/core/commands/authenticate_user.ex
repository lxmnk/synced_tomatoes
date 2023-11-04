defmodule SyncedTomatoes.Core.Commands.AuthenticateUser do
  alias SyncedTomatoes.Core.Token
  alias SyncedTomatoes.Repos.Postgres

  def execute(token_value) do
    case Postgres.get_by(Token, value: token_value) do
      nil ->
        {:error, :invalid_credentials}

      token ->
        {:ok, token.user_id}
    end
  end
end

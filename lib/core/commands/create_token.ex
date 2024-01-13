defmodule SyncedTomatoes.Core.Commands.CreateToken do
  alias SyncedTomatoes.Core.Token
  alias SyncedTomatoes.Repos.Postgres

  @token_bytes 32

  def execute(user_id) do
    token =
      @token_bytes
      |> :crypto.strong_rand_bytes()
      |> Base.encode16()

    Postgres.insert(%Token{user_id: user_id, value: token})
  end
end

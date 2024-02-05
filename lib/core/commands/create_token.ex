defmodule SyncedTomatoes.Core.Commands.CreateToken do
  alias SyncedTomatoes.Core.Token
  alias SyncedTomatoes.Repos.Postgres

  @token_bytes 32

  def execute(user_id, device_id) do
    token_value =
      @token_bytes
      |> :crypto.strong_rand_bytes()
      |> Base.encode16()

    token = %Token{user_id: user_id, value: token_value, device_id: device_id}

    Postgres.insert(token)
  end
end

defmodule SyncedTomatoes.Core.Commands.RegisterUser do
  import Ecto.Changeset

  alias SyncedTomatoes.Core.User
  alias SyncedTomatoes.Repos.Postgres

  def execute(login) do
    %{login: login}
    |> User.create_changeset()
    |> Postgres.insert()
  end
end

defmodule SyncedTomatoes.Core.Commands.RegisterUser do
  alias Ecto.Multi
  alias SyncedTomatoes.Core.User
  alias SyncedTomatoes.Repos.Postgres

  def execute(login) do
    result =
      Multi.new()
      |> Multi.insert(:user, User.create_changeset(%{login: login}))
      |> Multi.insert(:settings, fn %{user: user} ->
        Ecto.build_assoc(user, :settings)
      end)
      |> Postgres.transaction()

    case result do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, :user, %{errors: [login: {"has already been taken", _}]}, _} ->
        {:error, :login_already_exists}
    end
  end
end

defmodule SyncedTomatoes.Core.User do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  @required_attrs ~w(login)a

  schema "users" do
    field :login, :string, primary_key: true

    timestamps()
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @required_attrs)
    |> unique_constraint(:login, name: :users_pkey)
  end
end

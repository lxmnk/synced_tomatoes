defmodule SyncedTomatoes.Core.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias SyncedTomatoes.Core.Settings

  @all_fields ~w(login)a

  schema "users" do
    has_one :settings, Settings
    field :login, :string

    timestamps()
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @all_fields)
    |> unique_constraint(:login, name: :unique_login)
  end
end

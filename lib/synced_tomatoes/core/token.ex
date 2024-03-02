defmodule SyncedTomatoes.Core.Token do
  use Ecto.Schema

  alias SyncedTomatoes.Core.User

  schema "tokens" do
    belongs_to :user, User

    field :value, :string
    field :device_id, Ecto.UUID

    timestamps(updated_at: false)
  end
end

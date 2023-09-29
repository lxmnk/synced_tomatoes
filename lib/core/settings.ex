defmodule SyncedTomatoes.Core.Settings do
  use Ecto.Schema

  alias SyncedTomatoes.Core.User

  schema "settings" do
    belongs_to :user, User

    field :work_min, :integer, default: 25
    field :short_break_min, :integer, default: 5
    field :long_break_min, :integer, default: 15
    field :work_intervals_count, :integer, default: 4

    timestamps()
  end
end

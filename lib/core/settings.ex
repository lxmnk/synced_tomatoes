defmodule SyncedTomatoes.Core.Settings do
  use Ecto.Schema

  import Ecto.Changeset

  alias SyncedTomatoes.Core.User

  @primary_key false

  @required_fields ~w(
    user_id
  )a
  @optional_fields ~w(
    work_min
    short_break_min
    long_break_min
    work_intervals_count
  )a
  @all_fields @required_fields ++ @optional_fields

  schema "settings" do
    belongs_to :user, User, primary_key: true

    field :work_min, :integer, default: 25
    field :short_break_min, :integer, default: 5
    field :long_break_min, :integer, default: 15
    field :work_intervals_count, :integer, default: 4
    field :auto_next, :boolean, default: true

    timestamps()
  end

  def changeset(settings, params \\ %{}) do
    settings
    |> cast(params, @all_fields)
    |> validate_required(@required_fields)
    |> validate_number(:work_min, greater_than: 0)
    |> validate_number(:short_break_min, greater_than: 0)
    |> validate_number(:long_break_min, greater_than: 0)
    |> validate_number(:work_intervals_count, greater_than: 0)
  end
end

defmodule SyncedTomatoes.Core.TimerDump do
  use Ecto.Schema

  import Ecto.Changeset

  alias SyncedTomatoes.Core.User

  @primary_key false

  @required_fields ~w(
    user_id
  )a
  @optional_fields ~w(
    interval_type
    current_work_interval
    time_left_ms
  )a
  @all_fields @required_fields ++ @optional_fields

  schema "timer_dumps" do
    belongs_to :user, User, primary_key: true

    field :interval_type, :string
    field :current_work_interval, :integer
    field :time_left_ms, :integer

    timestamps()
  end

  def changeset(dump, params \\ %{}) do
    dump
    |> cast(params, @all_fields)
    |> validate_required(@required_fields)
  end
end

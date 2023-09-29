defmodule SyncedTomatoes.Repos.Postgres.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :user_id, references("users", on_delete: :delete_all)

      add :work_min, :integer
      add :short_break_min, :integer
      add :long_break_min, :integer
      add :work_intervals_count, :integer

      timestamps()
    end
  end
end

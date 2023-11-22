defmodule SyncedTomatoes.Repos.Postgres.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add :user_id, references("users", on_delete: :delete_all), primary_key: true

      add :work_min, :integer
      add :short_break_min, :integer
      add :long_break_min, :integer
      add :work_intervals_count, :integer
      add :auto_next, :boolean

      timestamps()
    end
  end
end

defmodule SyncedTomatoes.Repos.Postgres.Migrations.CreateTimerDumps do
  use Ecto.Migration

  def change do
    create table(:timer_dumps, primary_key: false) do
      add :user_id, references("users", on_delete: :delete_all), primary_key: true

      add :interval_type, :string
      add :current_work_interval, :integer
      add :time_left_ms, :integer

      timestamps()
    end
  end
end

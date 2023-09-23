defmodule SyncedTomatoes.Repos.Postgres.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :login, :string, primary_key: true

      timestamps()
    end
  end
end

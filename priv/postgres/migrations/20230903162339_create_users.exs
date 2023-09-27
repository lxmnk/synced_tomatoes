defmodule SyncedTomatoes.Repos.Postgres.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :login, :string

      timestamps()
    end

    create unique_index(:users, ~w(login)a, name: :unique_login)
  end
end

defmodule SyncedTomatoes.Repos.Postgres.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :user_id, references("users", on_delete: :delete_all)

      add :value, :string

      timestamps(updated_at: false)
    end

    create index(:tokens, ~w(value)a)
    create unique_index(:tokens, ~w(user_id)a, name: :one_token)
  end
end

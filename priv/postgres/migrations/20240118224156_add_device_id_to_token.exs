defmodule SyncedTomatoes.Repos.Postgres.Migrations.AddDeviceIdToToken do
  use Ecto.Migration

  def change do
    execute """
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp"
    """

    alter table(:tokens) do
      add :device_id, :uuid
    end

    flush()

    execute """
      UPDATE tokens SET device_id = uuid_generate_v4()
    """
  end
end

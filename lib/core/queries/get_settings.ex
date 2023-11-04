defmodule SyncedTomatoes.Core.Queries.GetSettings do
  alias SyncedTomatoes.Core.Settings
  alias SyncedTomatoes.Repos.Postgres

  def execute(user_id) do
    case Postgres.get_by(Settings, user_id: user_id) do
      nil ->
        {:error, :not_found}

      settings ->
        {:ok, settings}
    end
  end
end

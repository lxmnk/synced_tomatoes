defmodule SyncedTomatoes.Core.Commands.UpdateSettings do
  alias SyncedTomatoes.Core.{EctoHelpers, Settings}
  alias SyncedTomatoes.Repos.Postgres

  require Logger

  def execute(user_id, params) do
    result =
      %Settings{user_id: user_id}
      |> Settings.changeset(params)
      |> Postgres.update()

    case result do
      {:ok, _} ->
        :ok

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, EctoHelpers.build_reason(changeset)}

      {:error, reason} ->
        Logger.error("#{__ENV__.function} failed with: #{inspect(reason)}")
        {:error, "Settings update failed"}
    end
  end
end

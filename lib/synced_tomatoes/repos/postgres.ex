defmodule SyncedTomatoes.Repos.Postgres do
  use Ecto.Repo, otp_app: :synced_tomatoes, adapter: Ecto.Adapters.Postgres
end

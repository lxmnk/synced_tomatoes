import Config

config :synced_tomatoes, SyncedTomatoes.Repos.Postgres,
  database: "synced_tomatoes_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

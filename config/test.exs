import Config

config :synced_tomatoes,
  config_impl: SyncedTomatoes.Mocks.Config,
  websocket_cleanup_enabled?: false

config :synced_tomatoes, SyncedTomatoes.Repos.Postgres,
  database: "synced_tomatoes_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

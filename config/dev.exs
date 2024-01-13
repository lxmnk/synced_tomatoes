import Config

config :synced_tomatoes, SyncedTomatoes.Repos.Postgres,
  database: "synced_tomatoes_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

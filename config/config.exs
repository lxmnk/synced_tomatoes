import Config

config :synced_tomatoes,
  ecto_repos: [SyncedTomatoes.Repos.Postgres]

import_config "#{config_env()}.exs"

defmodule SyncedTomatoes.Application do
  use Application

  def start(_type, _args) do
    children = [
      SyncedTomatoes.Repos.Postgres,
      {Plug.Cowboy, scheme: :http, plug: SyncedTomatoes.Web.API, options: [port: 4000]},
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: SyncedTomatoes.Supervisor)
  end
end

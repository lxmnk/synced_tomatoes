defmodule SyncedTomatoes.Application do
  use Application

  def start(_type, _args) do
    children =
      [
        SyncedTomatoes.Repos.Postgres,
        cowboy_spec(),
        add_if(SyncedTomatoes.Core.TimerSupervisor, Mix.env() != :test)
      ]
      |> Enum.reject(fn spec -> is_nil(spec) end)

    Supervisor.start_link(children, strategy: :one_for_one, name: SyncedTomatoes.Supervisor)
  end

  defp cowboy_spec do
    {
      Plug.Cowboy,
      scheme: :http,
      plug: SyncedTomatoes.Web.API,
      options: [
        port: SyncedTomatoes.http_port,
        dispatch: cowboy_dispatch()
      ]
    }
  end

  defp cowboy_dispatch do
    [
      {:_, [
        {"/ws", SyncedTomatoes.Web.WebSocket, []},
        {:_, Plug.Cowboy.Handler, {SyncedTomatoes.Web.API, []}}
      ]}
    ]
  end

  defp add_if(spec, true) do
    spec
  end
  defp add_if(_, false) do
    nil
  end
end

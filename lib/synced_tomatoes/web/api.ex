defmodule SyncedTomatoes.Web.API do
  use Plug.Builder

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jsonrs

  plug Plug.MethodOverride
  plug Plug.Head

  plug SyncedTomatoes.Web.Router
end

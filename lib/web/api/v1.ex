defmodule SyncedTomatoes.Web.API.V1 do
  use SyncedTomatoes.Web, :router

  alias SyncedTomatoes.Web.API.V1

  post "/register", to: V1.Register
end

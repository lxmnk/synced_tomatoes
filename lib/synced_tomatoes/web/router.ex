defmodule SyncedTomatoes.Web.Router do
  use SyncedTomatoes.Web, :router

  post "/api/v1/register", to: SyncedTomatoes.Web.API.V1.Register
end

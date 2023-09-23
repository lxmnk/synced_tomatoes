defmodule SyncedTomatoes.Web.Router do
  use SyncedTomatoes.Web, :router

  forward "/api/v1", to: SyncedTomatoes.Web.API.V1
end

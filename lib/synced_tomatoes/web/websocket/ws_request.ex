defmodule SyncedTomatoes.Web.WebSocket.WSRequest do
  alias SyncedTomatoes.Core.Types.UUID4

  use Construct do
    field :id, UUID4
    field :method, :string
    field :params, :map
  end
end

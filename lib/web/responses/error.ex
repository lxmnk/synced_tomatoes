defmodule SyncedTomatoes.Responses.Error do
  defstruct status_code: 400, reason: nil, context: %{}
end

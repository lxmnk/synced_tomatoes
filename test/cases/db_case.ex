defmodule Test.Cases.DBCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      use Plug.Test

      import Test.Cases.DBCase
      import SyncedTomatoes.Factory
      import SyncedTomatoes.Mocks.Config, only: [put_env: 2, put_env: 3]

      alias SyncedTomatoes.Core.Types.UUID4
      alias SyncedTomatoes.Repos.Postgres
    end
  end

  setup do
    :ok = Sandbox.checkout(SyncedTomatoes.Repos.Postgres)
    Sandbox.mode(SyncedTomatoes.Repos.Postgres, {:shared, self()})
  end
end

defmodule Test.Cases.WSCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  alias SyncedTomatoes.Core.Types.UUID4
  alias Test.WSClient

  using do
    quote do
      import SyncedTomatoes.Factory
      import SyncedTomatoes.Mocks.Config, only: [put_env: 2, put_env: 3]
      import Test.Cases.WSCase

      alias SyncedTomatoes.Core.Types.UUID4
      alias SyncedTomatoes.Repos.Postgres
      alias Test.WSClient
    end
  end

  setup do
    :ok = Sandbox.checkout(SyncedTomatoes.Repos.Postgres)
    Sandbox.mode(SyncedTomatoes.Repos.Postgres, {:shared, self()})
  end

  def ws_send(token, text) when is_binary(token) do
    {:ok, pid} = WSClient.start_link(token: token)

    with :ok <- WSClient.connect(pid),
         :ok <- WSClient.send_text(pid, text)
    do
      {:ok, pid}
    end
  end

  def build_rpc(method, params) do
    Jsonrs.encode!(%{id: UUID4.generate(), method: method, params: params})
  end

  def rpc_call(token, method, params \\ %{}) do
    request = build_rpc(method, params)

    ws_send(token, request)
  end

  def rpc_event(pid) do
    with {:ok, raw_event} <- WSClient.receive_text(pid) do
      Jsonrs.decode(raw_event)
    end
  end
end

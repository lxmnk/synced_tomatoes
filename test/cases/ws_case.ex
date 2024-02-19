defmodule Test.Cases.WSCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias SyncedTomatoes.Core.Types.UUID4

  using do
    quote do
      import Test.Cases.WSCase
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

  def raw_call(pid, text) when is_pid(pid) do
    with :ok <- Test.WebSocketClient.send_text(pid, text) do
      Test.WebSocketClient.receive_text(pid)
    end
  end
  def raw_call(token, text) do
    {:ok, pid} = Test.WebSocketClient.start_link(token: token)

    with :ok <- Test.WebSocketClient.connect(pid),
         :ok <- Test.WebSocketClient.send_text(pid, text),
         {:ok, reply} <- Test.WebSocketClient.receive_text(pid),
         :ok <- Test.WebSocketClient.disconnect(pid)
    do
      {:ok, reply}
    end
  end

  def rpc_call(token_or_pid, method, params) do
    id = UUID4.generate()
    request = Jsonrs.encode!(%{id: id, method: method, params: params})

    with {:ok, raw_reply} <- raw_call(token_or_pid, request),
         {:ok, reply} <- Jsonrs.decode(raw_reply),
         :ok <- rpc_id_matches(id, reply["id"])
    do
      {:ok, reply}
    end
  end

  def rpc_event(pid) do
    with {:ok, raw_event} <- Test.WebSocketClient.receive_text(pid) do
      Jsonrs.decode(raw_event)
    end
  end

  defp rpc_id_matches(id, id) do
    :ok
  end
  defp rpc_id_matches(_, _) do
    {:error, :ids_dont_match}
  end
end

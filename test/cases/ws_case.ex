defmodule Test.Cases.WSCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias SyncedTomatoes.Core.UUID4

  using do
    quote do
      import Test.Cases.WSCase
      import SyncedTomatoes.Factory

      alias SyncedTomatoes.Core.UUID4
    end
  end

  setup do
    :ok = Sandbox.checkout(SyncedTomatoes.Repos.Postgres)
    Sandbox.mode(SyncedTomatoes.Repos.Postgres, {:shared, self()})
  end

  defmacro raw_call(token \\ nil, binary) do
    quote do
      {:ok, conn} = Mint.HTTP.connect(:http, "127.0.0.1", SyncedTomatoes.http_port)
      {:ok, conn, ref} = Mint.WebSocket.upgrade(:ws, conn, "/ws?token=#{unquote(token)}", [])

      upgrade_reply = receive(do: (message -> message))
      {:ok, conn, [{:status, ^ref, status}, {:headers, ^ref, resp_headers}, {:done, ^ref}]} =
        Mint.WebSocket.stream(conn, upgrade_reply)

      {:ok, conn, websocket} = Mint.WebSocket.new(conn, ref, status, resp_headers)

      {:ok, websocket, data} = Mint.WebSocket.encode(websocket, {:text, unquote(binary)})
      {:ok, conn} = Mint.WebSocket.stream_request_body(conn, ref, data)

      message_reply = receive(do: (message -> message))

      {:ok, _, [{:data, ^ref, data}]} = Mint.WebSocket.stream(conn, message_reply)

      case Mint.WebSocket.decode(websocket, data) do
        {:ok, _, [{:text, response}]} ->
          {:ok, response}

        {:ok, response, [frame]} ->
          {:error, frame}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defmacro call!(token, method, params) do
    quote do
      id = UUID4.generate()
      request = Jsonrs.encode!(%{id: id, method: unquote(method), params: unquote(params)})

      response =
        case raw_call(unquote(token), request) do
          {:ok, response} ->
            Jsonrs.decode!(response)

          {:error, reason} ->
            raise RuntimeError, message: inspect(reason)
        end

      assert response["id"] == id, "request and response `id`s don't match"

      response
    end
  end
end

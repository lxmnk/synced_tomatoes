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

  defmodule WSConnection do
    defstruct ~w(conn ref websocket)a
  end

  def open_websocket(token) do
    {:ok, conn} = Mint.HTTP.connect(:http, "127.0.0.1", SyncedTomatoes.http_port)
    {:ok, conn, ref} = Mint.WebSocket.upgrade(:ws, conn, "/ws?token=#{token}", [])

    {:ok, upgrade_reply} = receive_with_timeout()

    {:ok, conn, [{:status, ^ref, status}, {:headers, ^ref, resp_headers}, {:done, ^ref}]} =
      Mint.WebSocket.stream(conn, upgrade_reply)

    {:ok, conn, websocket} = Mint.WebSocket.new(conn, ref, status, resp_headers)

    {:ok, %WSConnection{conn: conn, ref: ref, websocket: websocket}}
  end

  def close_websocket(%WSConnection{conn: conn, ref: ref, websocket: websocket}) do
    {:ok, websocket, data} = Mint.WebSocket.encode(websocket, :close)

    with {:ok, conn} <- Mint.WebSocket.stream_request_body(conn, ref, data),
         {:ok, close_response} <- receive_with_timeout(),
         {:ok, conn, [{:data, ^ref, data}]} <- Mint.WebSocket.stream(conn, close_response)
    do
      {:ok, _, [{:close, 1_000, ""}]} = Mint.WebSocket.decode(websocket, data)

      Mint.HTTP.close(conn)
    end
  end

  def send_event(%WSConnection{conn: conn, ref: ref, websocket: websocket}, binary) do
    {:ok, websocket, data} = Mint.WebSocket.encode(websocket, {:text, binary})
    {:ok, conn} = Mint.WebSocket.stream_request_body(conn, ref, data)

    {:ok, %WSConnection{conn: conn, ref: ref, websocket: websocket}}
  end

  def receive_frame(%WSConnection{conn: conn, ref: ref, websocket: websocket}) do
    with {:ok, message_reply} <- receive_with_timeout(),
         {:ok, _, [{:data, ^ref, data}]} <- Mint.WebSocket.stream(conn, message_reply),
         {:ok, _, [{:text, event}]} <- Mint.WebSocket.decode(websocket, data)
    do
      {:ok, event}
    else
      {:ok, _, [frame]} ->
        {:error, frame}

      error ->
        error
    end
  end

  def receive_event!(ws_connection) do
    case receive_frame(ws_connection) do
      {:ok, response} ->
        Jsonrs.decode!(response)

      {:error, reason} ->
        raise RuntimeError, message: inspect(reason)
    end
  end

  def raw_call(%WSConnection{} = ws_connection, binary) do
    {:ok, ws_connection} = send_event(ws_connection, binary)

    receive_frame(ws_connection)
  end
  def raw_call(token, binary) do
    {:ok, ws_connection} = open_websocket(token)

    {:ok, ws_connection} = send_event(ws_connection, binary)

    call_result = receive_frame(ws_connection)

    close_websocket(ws_connection)

    call_result
  end

  def call!(token_or_ws_connection, method, params) do
    id = UUID4.generate()
    request = Jsonrs.encode!(%{id: id, method: method, params: params})

    response =
      case raw_call(token_or_ws_connection, request) do
        {:ok, response} ->
          Jsonrs.decode!(response)

        {:error, reason} ->
          raise RuntimeError, message: inspect(reason)
      end

    assert response["id"] == id, "request and response `id`s don't match"

    response
  end

  defp receive_with_timeout(timeout \\ 1_000) do
    reply =
      receive do
        message -> message
      after
        timeout -> {:error, :frame_not_received}
      end

    case reply do
      {:tcp, _, _} ->
        {:ok, reply}

      error ->
        error
    end
  end
end

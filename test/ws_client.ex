defmodule Test.WSClient do
  use GenServer

  defmodule State do
    defstruct ~w(token notifier_pid conn ref websocket)a
  end

  def start_link(opts) do
    opts = Keyword.put(opts, :notifier_pid, self())

    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    token = Keyword.fetch!(opts, :token)
    notifier_pid = Keyword.fetch!(opts, :notifier_pid)

    {:ok, %State{token: token, notifier_pid: notifier_pid}}
  end

  def connect(pid) do
    GenServer.call(pid, :connect)
  end

  def disconnect(pid) do
    GenServer.call(pid, :disconnect)
  end

  def send_text(pid, text) do
    GenServer.call(pid, {:send_text, text})
  end

  def receive_text(pid) do
    GenServer.call(pid, :receive_text)
  end

  @impl true
  def handle_call(:connect, _, %{token: token} = state) do
    {:ok, conn} = Mint.HTTP.connect(:http, "127.0.0.1", SyncedTomatoes.http_port)
    {:ok, conn, ref} = Mint.WebSocket.upgrade(:ws, conn, "/ws?token=#{token}", [])

    {:ok, upgrade_reply} = receive_tcp_frame()

    {:ok, conn, [{:status, ^ref, status}, {:headers, ^ref, resp_headers}, {:done, ^ref}]} =
      Mint.WebSocket.stream(conn, upgrade_reply)

    {:ok, conn, websocket} = Mint.WebSocket.new(conn, ref, status, resp_headers)

    {:reply, :ok, %{state | conn: conn, ref: ref, websocket: websocket}}
  end

  @impl true
  def handle_call(:disconnect, _, %{conn: conn, ref: ref, websocket: websocket} = state) do
    {:ok, websocket, data} = Mint.WebSocket.encode(websocket, :close)

    with {:ok, conn} <- Mint.WebSocket.stream_request_body(conn, ref, data),
         {:ok, close_response} <- receive_tcp_frame(),
         {:ok, conn, [{:data, ^ref, data}]} <- Mint.WebSocket.stream(conn, close_response)
    do
      {:ok, _, [{:close, 1_000, ""}]} = Mint.WebSocket.decode(websocket, data)

      Mint.HTTP.close(conn)

      {:reply, :ok, %{state | conn: nil, ref: nil, websocket: nil}}
    end
  end

  @impl true
  def handle_call({:send_text, text}, _, %{conn: conn, ref: ref, websocket: websocket} = state) do
    {:ok, websocket, data} = Mint.WebSocket.encode(websocket, {:text, text})
    {:ok, conn} = Mint.WebSocket.stream_request_body(conn, ref, data)

    {:reply, :ok, %{state | conn: conn, ref: ref, websocket: websocket}}
  end

  @impl true
  def handle_call(:receive_text, _, %{conn: conn, ref: ref, websocket: websocket} = state) do
    with {:ok, reply} <- receive_tcp_frame(),
         {:ok, _, [{:data, ^ref, data}]} <- Mint.WebSocket.stream(conn, reply),
         {:ok, _, [{:text, text}]} <- Mint.WebSocket.decode(websocket, data)
    do
      {:reply, {:ok, text}, %{state | conn: conn, ref: ref, websocket: websocket}}
    else
      {:ok, _, [frame]} ->
        {:reply, {:error, frame}, %{state | conn: conn, ref: ref, websocket: websocket}}

      {:error, reason} ->
        {:reply, {:error, reason}, %{state | conn: conn, ref: ref, websocket: websocket}}
    end
  end

  @impl true
  def handle_info(
    {:tcp, _, _} = tcp_frame,
    %{notifier_pid: notifier_pid, conn: conn, ref: ref, websocket: websocket} = state
  )
  do
    with {:ok, _, [{:data, ^ref, data}]} <- Mint.WebSocket.stream(conn, tcp_frame),
         {:ok, _, [{:text, text}]} <- Mint.WebSocket.decode(websocket, data)
    do
      event = maybe_decode_event(text)
      send(notifier_pid, {{__MODULE__, self()}, event})
    end

    {:noreply, %{state | conn: conn, ref: ref, websocket: websocket}}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp maybe_decode_event(text) do
    case Jsonrs.decode(text) do
      {:ok, decoded} ->
        decoded

      _ ->
        text
    end
  end

  defp receive_tcp_frame(timeout \\ 1_000) do
    receive do
      {:tcp, _, _} = reply ->
        {:ok, reply}

      {:error, reason} ->
        {:error, reason}
    after
      timeout ->
        {:error, :frame_not_received}
    end
  end
end

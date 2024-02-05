defmodule SyncedTomatoes.Web.WebSocket do
  @behaviour :cowboy_websocket

  alias Plug.Conn.Query
  alias SyncedTomatoes.Core.Commands.{AuthenticateUser, DumpTimer}
  alias SyncedTomatoes.Core.TimerSupervisor
  alias SyncedTomatoes.Web.WebSocket.{MethodDispatcher, WSRequest}
  alias SyncedTomatoes.Web.WebSocketRegistry

  require Logger

  @invalid_credentials_frame {:close, 1008, "Invalid credentials"}

  def init(request, _) do
    state = %{token: Query.decode(request.qs)["token"]}

    {:cowboy_websocket, request, state, %{compress: true}}
  end

  def websocket_init(%{token: nil}) do
    {[@invalid_credentials_frame], %{}}
  end
  def websocket_init(%{token: token_value}) do
    case AuthenticateUser.execute(token_value) do
      {:ok, token} ->
        WebSocketRegistry.add(token.user_id, token.device_id)

        state = %{
          user_id: token.user_id,
          device_id: token.device_id,
          websocket_pid: self()
        }

        {:ok, state, :hibernate}

      {:error, :invalid_credentials} ->
        {[@invalid_credentials_frame], %{}}
    end
  end

  def websocket_handle({:text, request}, state) do
    with {:ok, payload} <- Jsonrs.decode(request),
         {:ok, ws_request} <- WSRequest.make(payload)
    do
      case MethodDispatcher.dispatch(ws_request.method, state, ws_request.params) do
        :ok ->
          response = Jsonrs.encode!(%{id: ws_request.id, result: %{info: "Success"}})
          {:reply, {:text, response}, state, :hibernate}

        {:ok, result} ->
          response = Jsonrs.encode!(%{id: ws_request.id, result: result})
          {:reply, {:text, response}, state, :hibernate}

        {:error, reason} ->
          response = Jsonrs.encode!(%{
            id: ws_request.id,
            error: "Method call error",
            reason: reason
          })
          {:reply, {:text, response}, state, :hibernate}

        error ->
          Logger.error("Unhandled method error: #{inspect(error)}")

          response = Jsonrs.encode!(%{
            id: ws_request.id,
            error: "Method call error",
            reason: "Internal error"
          })
          {:reply, {:text, response}, state, :hibernate}
      end
    else
      {:error, reason} ->
        response = Jsonrs.encode!(%{
          id: nil,
          error: "Request validation error",
          reason: reason
        })

        {:reply, {:text, response}, state, :hibernate}
    end
  end

  def websocket_info(message, state) when is_atom(message) do
    event = Jsonrs.encode!(%{
      event: message,
      payload: %{}
    })

    {:reply, {:text, event}, state, :hibernate}
  end
  def websocket_info(_, state) do
    {:ok, state, :hibernate}
  end

  def terminate(_, _, %{user_id: user_id}) do
    if SyncedTomatoes.websocket_cleanup_enabled?() do
      DumpTimer.execute(user_id)
      TimerSupervisor.stop_timer(user_id)
    end

    :ok
  end
  def terminate(_, _, %{}) do
    :ok
  end
end

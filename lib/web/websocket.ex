defmodule SyncedTomatoes.Web.WebSocket do
  @behaviour :cowboy_websocket

  alias Plug.Conn.Query
  alias SyncedTomatoes.Core.Commands.AuthenticateUser
  alias SyncedTomatoes.Web.WebSocket.MethodDispatcher
  alias SyncedTomatoes.Web.WebSocket.WSRequest

  @invalid_credentials_frame {:close, 1008, "Invalid credentials"}

  def init(request, _) do
    state = %{token: Query.decode(request.qs)["token"]}

    {:cowboy_websocket, request, state, %{compress: true}}
  end

  def websocket_init(%{token: nil}) do
    {[@invalid_credentials_frame], %{}}
  end
  def websocket_init(%{token: token}) do
    case AuthenticateUser.execute(token) do
      {:ok, user_id} ->
        {:ok, %{user_id: user_id}, :hibernate}

      {:error, :invalid_credentials} ->
        {[@invalid_credentials_frame], %{}}
    end
  end

  def websocket_handle({:text, request}, state) do
    with {:ok, payload} <- Jsonrs.decode(request),
         {:ok, ws_request} <- WSRequest.make(payload)
    do
      case MethodDispatcher.dispatch(ws_request.method, state, ws_request.params) do
        {:ok, result} ->
          response = Jsonrs.encode!(%{id: ws_request.id, result: result})
          {:reply, {:text, response}, state, :hibernate}

        {:error, reason} ->
          response = Jsonrs.encode!(%{
            id: ws_request.id,
            error: "Method call error",
            reason: inspect_(reason)
          })
          {:reply, {:text, response}, state, :hibernate}
      end
    else
      {:error, reason} ->
        response = Jsonrs.encode!(%{
          id: nil,
          error: "Request validation error",
          reason: inspect_(reason)
        })

        {:reply, {:text, response}, state, :hibernate}
    end
  end

  def websocket_info(_, state) do
    {:ok, state, :hibernate}
  end

  defp inspect_(value) when is_binary(value) do
    value
  end
  defp inspect_(value) do
    inspect(value)
  end
end

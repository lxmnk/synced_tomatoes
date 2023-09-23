defmodule SyncedTomatoes.Web.Endpoint do
  import Plug.Conn

  alias SyncedTomatoes.Responses.{Error, Ok}

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro endpoint(func) do
    quote do
      alias SyncedTomatoes.Responses.{Error, Ok}

      def init(opts) do
        opts
      end

      def call(conn, _opts) do
        schema =
          case Code.ensure_compiled(__MODULE__.RequestSchema) do
            {:module, _} ->
              __MODULE__.RequestSchema

            _ ->
              nil
          end

        case unquote(__MODULE__).validate_body(schema, conn.body_params) do
          {:ok, payload} ->
            result = unquote(func).(conn, payload)
            cast_result(result, conn)

          {:error, reason} ->
            resp_body = Jsonrs.encode!(%{"status" => "error", "reason" => reason})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, resp_body)
            |> halt()
        end
      end
    end
  end

  def validate_body(nil, params) do
    {:ok, params}
  end
  def validate_body(schema, params) do
    schema.make(params)
  end

  def cast_result(%Ok{} = ok, conn) do
    resp_body = Jsonrs.encode!(%{"status" => "ok", "result" => ok.result})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(ok.status_code, resp_body)
  end
  def cast_result(%Error{} = error, conn) do
    resp_body = Jsonrs.encode!(
      %{"status" => "error", "reason" => error.reason, "context" => error.context}
    )

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(error.status_code, resp_body)
    |> halt()
  end
  def cast_result(%Plug.Conn{} = conn, _) do
    conn
  end
  def cast_result(_, _) do
    raise "Invalid response type"
  end
end

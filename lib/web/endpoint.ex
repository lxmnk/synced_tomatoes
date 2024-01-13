defmodule SyncedTomatoes.Web.Endpoint do
  import Plug.Conn

  alias SyncedTomatoes.Web.API.Responses.{Error, Ok}

  @callback execute(context :: Plug.Conn, payload :: map) :: %Ok{} | %Error{}
  @callback request_schema() :: struct
  @optional_callbacks request_schema: 0

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      alias SyncedTomatoes.Web.API.Responses.{Error, Ok}

      def request_schema, do: nil

      defoverridable request_schema: 0

      def init(opts) do
        opts
      end

      def call(conn, _opts) do
        case unquote(__MODULE__).validate_body(request_schema(), conn.body_params) do
          {:ok, payload} ->
            result = __MODULE__.execute(conn, payload)

            unquote(__MODULE__).cast_result(result, conn)

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
    resp_body = Jsonrs.encode!(%{
      "status" => "ok",
      "result" => ok.result,
      "info" => ok.info || "Success"
    })

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

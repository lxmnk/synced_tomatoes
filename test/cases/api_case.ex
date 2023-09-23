defmodule Test.Cases.APICase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn.Utils, as: ConnUtils

  using do
    quote do
      use Plug.Test

      import Test.Cases.APICase
    end
  end

  setup do
    :ok = Sandbox.checkout(SyncedTomatoes.Repos.Postgres)
    Sandbox.mode(SyncedTomatoes.Repos.Postgres, {:shared, self()})
  end

  @endpoint_mod SyncedTomatoes.Web.API
  @http_methods ~w(get post)a

  for method <- @http_methods do
    defmacro unquote(method)(path, params_or_body \\ nil) do
      method = unquote(method)

      quote bind_quoted: [
        endpoint_mod: @endpoint_mod,
        method: method,
        path: path,
        params_or_body: params_or_body
      ]
      do
        endpoint = endpoint_mod.init([])
        conn = Plug.Test.conn(method, path, params_or_body)

        endpoint_mod.call(conn, endpoint)
      end
    end
  end

  def ensure_status_code!(%Plug.Conn{status: expected_code} = conn, expected_code) do
    conn
  end
  def ensure_status_code!(%Plug.Conn{status: status_code, resp_body: body}, expected_code) do
    raise """
      Expected status code #{expected_code}, but #{status_code} received.
      Response body is `#{body}`
      """
  end

  def extract_body(%Plug.Conn{resp_body: body}) do
    body
  end

  def extract_json!(%Plug.Conn{resp_body: body} = conn) do
    ensure_content_type!(conn, "application/json")

    case Jsonrs.decode(body) do
      {:ok, result} ->
        result

      {:error, reason} ->
        raise "Can't decode json body: #{reason}"
    end
  end

  defp ensure_content_type!(conn, content_type) do
    case Plug.Conn.get_resp_header(conn, "content-type") do
      [] ->
        raise "No Content-Type header set"

      [header] ->
        ensure_content_type_header!(header, content_type)

      [_ | _] ->
        raise "Multiple Content-Type headers aren't supported"
    end
  end

  defp ensure_content_type_header!(header, content_type) do
    case ConnUtils.content_type(header) do
      {:ok, part, subpart, _} ->
        compare_content_types!("#{part}/#{subpart}", content_type)

      :error ->
        raise "Invalid Content-Type header #{content_type}"
    end
  end

  defp compare_content_types!(expected_type, expected_type) do
    :ok
  end
  defp compare_content_types!(actual_type, expected_type) do
    raise "Expected Content-Type `#{expected_type}`, but `#{actual_type}` received"
  end
end

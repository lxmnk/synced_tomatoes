defmodule SyncedTomatoes.Web do
  def router do
    quote do
      use Plug.Router

      plug :match
      plug :dispatch

      def match(conn, opts) do
        super(conn, opts)
      rescue FunctionClauseError ->
        conn |> send_resp(404, []) |> halt()
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

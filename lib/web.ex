defmodule SyncedTomatoes.Web do
  def router do
    quote do
      use Plug.Router
      use Plug.ErrorHandler

      import Module, only: [concat: 2]

      require Logger

      plug :match
      plug :dispatch

      def match(conn, opts) do
        super(conn, opts)
      rescue FunctionClauseError ->
        conn |> send_resp(404, []) |> halt()
      end

      def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
        formatted_stack = Exception.format_stacktrace(stack)
        Logger.error("Error #{kind} by reason #{reason}:\n#{formatted_stack}")

        send_resp(conn, conn.status, [])
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

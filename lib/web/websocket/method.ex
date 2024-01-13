defmodule SyncedTomatoes.Web.WebSocket.Method do
  @callback execute(context :: map, params :: map) :: :ok | {:ok, term} | {:error, term}
  @callback params_schema() :: struct
  @callback map_params(params :: map) :: map
  @callback map_result(result :: map) :: map
  @optional_callbacks params_schema: 0, map_params: 1, map_result: 1

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def params_schema, do: nil
      def map_params(params), do: params
      def map_result(result), do: result

      defoverridable params_schema: 0, map_params: 1, map_result: 1

      def call(context, payload) do
        with {:ok, params} <- unquote(__MODULE__).validate_params(params_schema(), payload) do
          case __MODULE__.execute(context, map_params(params)) do
            :ok ->
              :ok

            {:ok, result} ->
              {:ok, map_result(result)}

            error ->
              error
          end
        end
      end
    end
  end

  def validate_params(nil, params) do
    {:ok, params}
  end
  def validate_params(schema, params) do
    schema.make(params)
  end
end

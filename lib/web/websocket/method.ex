defmodule SyncedTomatoes.Web.WebSocket.Method do
  @callback execute(context :: map, params :: map) :: {:ok, term} | {:error, term}
  @callback map_params(params :: map) :: term
  @callback map_result(result :: map) :: term
  @optional_callbacks map_params: 1, map_result: 1

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def call(context, payload) do
        schema =
          case Code.ensure_compiled(__MODULE__.ParamsSchema) do
            {:module, _} ->
              __MODULE__.ParamsSchema

            _ ->
              nil
          end

        map_params =
          if function_exported?(__MODULE__, :map_params, 1) do
            fn params -> apply(__MODULE__, :map_params, [params]) end
          else
            fn params -> params end
          end

        map_result =
          if function_exported?(__MODULE__, :map_result, 1) do
            fn result -> apply(__MODULE__, :map_result, [result]) end
          else
            fn result -> result end
          end

        with {:ok, params} <- unquote(__MODULE__).validate_params(schema, payload),
             {:ok, result} <- __MODULE__.execute(context, map_params.(params))
        do
          {:ok, map_result.(result)}
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

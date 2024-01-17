defmodule SyncedTomatoes.Core.Types.PositiveInteger do
  @behaviour Construct.Type

  def cast(v) when is_integer(v) and v > 0, do: {:ok, v}
  def cast(_), do: {:error, :not_a_positive_integer}
end

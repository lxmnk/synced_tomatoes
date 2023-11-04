defmodule SyncedTomatoes.Core.UUID4 do
  defdelegate generate, to: UUID, as: :uuid4
  defdelegate to_string!(uuid), to: UUID, as: :binary_to_string!
  defdelegate from_string!(string), to: UUID, as: :string_to_binary!

  def cast(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid), do: {:ok, uuid}
  def cast(_), do: :error
end

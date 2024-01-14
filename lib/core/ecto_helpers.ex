defmodule SyncedTomatoes.Core.EctoHelpers do
  import Ecto.Changeset

  def build_reason(%Ecto.Changeset{valid?: false} = changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.take(1)
    |> Enum.map(fn {key, message} ->
      "#{key} #{message}"
    end)
    |> hd()
  end
end

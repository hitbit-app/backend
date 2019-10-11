defmodule Hitbit.Ecto.Helper do
  alias Ecto.Changeset

  def transaction_resolver({:ok, value}), do: value

  def transaction_resolver({:error, _fail_op, fail_val, _changes}),
    do: {:error, fail_val}

  def id_resolver({:ok, %{id: id}}), do: {:ok, id}
  def id_resolver({:error, changeset}), do: {:error, serialize(changeset)}

  def bool_resolver({:ok, _}), do: {:ok, true}
  def bool_resolver({:error, changeset}), do: {:error, serialize(changeset)}

  def serialize(%Changeset{errors: errors, changes: changes}) do
    for {field, error} <- errors do
      {message, _} = error

      if changes[field] == nil do
        "#{normalize(field)} #{message}"
      else
        "#{normalize(field)} '#{changes[field]}' #{message}"
      end
    end
  end

  defp uncapitalize(str) do
    first = String.slice(str, 0..0) |> String.downcase()
    first <> String.slice(str, 1..-1)
  end

  defp normalize(field),
    do: field |> Atom.to_string() |> Macro.camelize() |> uncapitalize()
end

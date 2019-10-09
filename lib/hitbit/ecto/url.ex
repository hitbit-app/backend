defmodule HitBit.Ecto.URL do
  @behaviour Ecto.Type

  def type, do: :string

  def cast(str), do: validate(str)

  def load(url), do: {:ok, url}

  def dump(str), do: validate(str)

  def embed_as(_), do: :self

  def equal?(term1, term2), do: term1 == term2

  defp validate(str) when is_binary(str) do
    case URI.parse(str) do
      %URI{scheme: nil} -> :error
      %URI{port: nil} -> :error
      _ -> {:ok, str}
    end
  end

  defp validate(_), do: :error
end

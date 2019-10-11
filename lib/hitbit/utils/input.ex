defmodule Hitbit.Utils.Input do
  def escape(str) do
    Jason.encode!(str)
  end

  defp do_read(prompt, default) do
    prompt
    |> IO.gets()
    |> String.slice(0..-2)
    |> case do
      "" when default != nil -> default
      "" -> :empty
      str -> str
    end
  end

  def read(prompt, default \\ nil) do
    if default == nil do
      "#{prompt}: "
    else
      "#{prompt} (#{default}): "
    end
    |> do_read(default)
  end

  def read_string(prompt, default \\ nil) do
    case read(prompt, default) do
      :empty -> read_string(prompt)
      str -> escape(str)
    end
  end

  def read_integer(prompt, default \\ nil)

  def read_integer(prompt, default) when is_integer(default),
    do: read_integer(prompt, to_string(default))

  def read_integer(prompt, default) do
    read(prompt, default)
    |> to_string()
    |> Integer.parse()
    |> case do
      {res, ""} -> res
      _ -> read_integer(prompt, default)
    end
  end

  defp do_ask_yn(prompt) do
    prompt
    |> do_read("")
    |> String.downcase()
    |> case do
      res when res in ["yes", "y"] -> {:ok, true}
      res when res in ["no", "n"] -> {:ok, false}
      "" -> :empty
      _ -> :error
    end
  end

  def ask_yn(prompt) do
    case do_ask_yn("#{prompt} [y/n]: ") do
      {:ok, res} -> res
      _ -> ask_yn(prompt)
    end
  end

  def ask_Yn(prompt) do
    case do_ask_yn("#{prompt} [Y/n]: ") do
      {:ok, res} -> res
      :empty -> true
      :error -> ask_Yn(prompt)
    end
  end

  def ask_yN(prompt) do
    case do_ask_yn("#{prompt} [y/N]: ") do
      {:ok, res} -> res
      :empty -> false
      :error -> ask_yN(prompt)
    end
  end
end

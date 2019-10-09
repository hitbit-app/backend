defmodule HitBit.Utils.Rand do
  def string(len \\ 64) do
    fn -> :crypto.strong_rand_bytes(1) end
    |> Stream.repeatedly()
    |> Stream.filter(fn <<b>> ->
      b in ?!..?~ and b not in [?$, ?\\, ?\", ?`]
    end)
    |> Enum.take(len)
    |> Enum.join()
  end
end

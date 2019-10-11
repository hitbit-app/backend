defmodule GraphQL.Types.EncId do
  use Absinthe.Schema.Notation

  defp secret_key(len \\ 32) do
    Application.get_env(:hitbit, HitbitWeb.Endpoint)
    |> Keyword.get(:secret_key_base, "")
    |> String.slice(0, len)
  end

  defp pad_bytes(binary, block \\ 16) do
    padding_bits =
      case rem(byte_size(binary), block) do
        0 -> 0
        r -> (block - r) * 8
      end

    <<0::size(padding_bits)>> <> binary
  end

  defp unpad_bytes(<<0, tail::bitstring>>), do: unpad_bytes(tail)
  defp unpad_bytes(binary), do: binary

  defp encrypt(raw_binary) do
    padded_binary = pad_bytes(raw_binary)

    :crypto.crypto_one_time(:aes_256_ecb, secret_key(), padded_binary, true)
  end

  defp decrypt(raw_enc) do
    :crypto.crypto_one_time(:aes_256_ecb, secret_key(), raw_enc, false)
    |> unpad_bytes()
    |> :erlang.binary_to_term()
  end

  def serialize(id) do
    id
    |> :erlang.term_to_binary()
    |> encrypt()
    |> Base.url_encode64(padding: false)
  end

  def parse(%{value: enc_id}) do
    try do
      {:ok, raw_enc} = Base.url_decode64(enc_id, padding: false)
      {:ok, decrypt(raw_enc)}
    rescue
      _ -> :error
    end
  end

  scalar :enc_id, name: "EncId" do
    serialize(&__MODULE__.serialize/1)

    parse(&__MODULE__.parse/1)
  end
end

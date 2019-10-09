defmodule HitBit.Auth do
  alias HitBit.Schemas.User

  def hash(pass), do: Argon2.hash_pwd_salt(pass)

  def verify(pass, hash), do: Argon2.verify_pass(pass, hash)

  def attempt(%{email: email, password: pass}) do
    user = HitBit.Repo.get_by(User, %{email: email})

    with %User{password_hash: hash} <- user,
         true <- verify(pass, hash),
         {:ok, token, _claims} <- HitBit.Guardian.encode_and_sign(user) do
      {:ok, token}
    else
      _ -> :error
    end
  end
end

defmodule Hitbit.Auth do
  alias Hitbit.Repo
  alias Hitbit.Guardian
  alias Hitbit.Schemas.{User, RevokedToken}

  @access_token_ttl {5, :minutes}
  @refresh_token_ttl {8, :weeks}
  @issue_new_refresh_token_after {4, :weeks}

  def hash(pass), do: Argon2.hash_pwd_salt(pass)

  def verify(pass, hash), do: Argon2.verify_pass(pass, hash)

  def get_header_token(%Plug.Conn{} = conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        {:ok, token}

      _ ->
        :error
    end
  end

  defp issue_token(resource, opts) do
    resource
    |> Guardian.encode_and_sign(%{}, opts)
    |> Tuple.delete_at(2)
  end

  defp issue_access_token(resource),
    do: issue_token(resource, token_type: "access", ttl: @access_token_ttl)

  defp issue_refresh_token(resource),
    do: issue_token(resource, token_type: "refresh", ttl: @refresh_token_ttl)

  def decode_access_token(token) do
    with {:ok, claims} <- Guardian.decode_and_verify(token),
         %{"typ" => "access", "sub" => subject} <- claims,
         %{"id" => id, "groups" => groups} <- subject,
         resource <- %{id: id, groups: groups} do
      {:ok, resource}
    else
      _ -> :error
    end
  end

  def login(%{email: email, password: pass}) do
    user = Hitbit.Repo.get_by(User, %{email: email})

    with %User{password_hash: hash} <- user,
         true <- verify(pass, hash),
         {:ok, access_token} <- issue_access_token(user),
         {:ok, refresh_token} <- issue_refresh_token(user),
         tokens <- %{
           access_token: access_token,
           refresh_token: refresh_token
         } do
      {:ok, tokens}
    else
      _ -> :error
    end
  end

  defp refresh_token_renewal_check(old_token, user) do
    %{claims: claims} = Guardian.peek(old_token)
    %{"iat" => issued_at} = claims
    token_life = Guardian.ttl_to_seconds(@issue_new_refresh_token_after)
    now = System.system_time(:second)

    if now > issued_at + token_life do
      {:ok, _} = Guardian.revoke(old_token)
      issue_refresh_token(user)
    else
      {:ok, nil}
    end
  end

  # Note that `Guardian.resource_from_claims` looks up
  # in the db, then if a user has been deleted his session
  # won't be renewed.
  def refresh(token) do
    with {:ok, claims} <- Guardian.decode_and_verify(token),
         %{"typ" => "refresh", "jti" => jti} <- claims,
         nil <- Repo.get(RevokedToken, jti),
         {:ok, user} <- Guardian.resource_from_claims(claims),
         {:ok, access_token} <- issue_access_token(user),
         {:ok, refresh_token} <- refresh_token_renewal_check(token, user),
         tokens <- %{
           access_token: access_token,
           refresh_token: refresh_token
         } do
      {:ok, tokens}
    else
      _ -> :error
    end
  end
end

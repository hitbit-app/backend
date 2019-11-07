defmodule Hitbit.Guardian do
  use Guardian, otp_app: :hitbit

  alias Hitbit.Repo
  alias Hitbit.Schemas.{User, RevokedToken}

  def subject_for_token(%User{} = resource, _claims) do
    subject = %{"id" => resource.id, "groups" => resource.groups}

    {:ok, subject}
  end

  # Database lookup is required here
  defp resource_from_subject(%{"id" => user_id}) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :no_such_user}

      user ->
        {:ok, user}
    end
  end

  defp resource_from_subject(_), do: {:error, :invalid_subject}

  def resource_from_claims(%{"sub" => subject}),
    do: resource_from_subject(subject)

  def resource_from_claims(_), do: {:error, :invalid_claims}

  def on_revoke(%{"jti" => jti} = claims, _token, _opts \\ []) do
    try do
      Repo.insert(%RevokedToken{jti: jti})

      {:ok, claims}
    rescue
      Ecto.ConstraintError ->
        {:error, :revoked_token}
    end
  end

  def ttl_to_seconds({seconds, unit}) when unit in [:second, :seconds],
    do: seconds

  def ttl_to_seconds({minutes, unit}) when unit in [:minute, :minutes],
    do: minutes * 60

  def ttl_to_seconds({hours, unit}) when unit in [:hour, :hours],
    do: hours * 60 * 60

  def ttl_to_seconds({days, unit}) when unit in [:day, :days],
    do: days * 24 * 60 * 60

  def ttl_to_seconds({weeks, unit}) when unit in [:week, :weeks],
    do: weeks * 7 * 24 * 60 * 60

  def ttl_to_seconds({_, units}),
    do: raise("Unknown Units: #{units}")
end

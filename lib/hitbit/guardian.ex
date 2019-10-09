defmodule HitBit.Guardian do
  use Guardian, otp_app: :hitbit

  alias HitBit.Schemas.User

  defp resource_to_subject(resource) do
    %{"id" => resource.id, "groups" => resource.groups}
  end

  defp subject_to_resource(subject) do
    case subject do
      %{"id" => id, "groups" => groups} ->
        {:ok, %{id: id, groups: groups}}

      _ ->
        {:error, :invalid_subject}
    end
  end

  def subject_for_token(%User{} = resource, _claims) do
    {:ok, resource_to_subject(resource)}
  end

  def subject_from_claims(%{"typ" => "access", "sub" => subject}) do
    subject_to_resource(subject)
  end

  def subject_from_claims(_), do: {:error, :invalid_claims}

  def subject_from_token(token) do
    case decode_and_verify(token) do
      {:ok, claims} -> subject_from_claims(claims)
      _ -> {:error, :decode_and_verify}
    end
  end

  def resource_from_subject(%{id: user_id}) do
    case HitBit.Repo.get(User, user_id) do
      nil -> {:error, :no_such_user}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(claims) do
    case subject_from_claims(claims) do
      {:ok, subject} -> resource_from_subject(subject)
      err -> err
    end
  end
end

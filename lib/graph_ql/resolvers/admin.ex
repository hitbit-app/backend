defmodule GraphQL.Resolvers.Admin do
  use GraphQL.AuthResolver,
    include: :admin_validation

  import Ecto.Query

  alias HitBit.Repo
  alias HitBit.Schemas.User

  defauth search_users(%{key: key}, _resolution) do
    search_key = "%#{key}%"

    query =
      from u in User,
        where: ilike(u.username, ^search_key),
        or_where: ilike(u.email, ^search_key)

    {:ok, Repo.all(query)}
  end
end

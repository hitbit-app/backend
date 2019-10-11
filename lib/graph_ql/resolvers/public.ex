defmodule GraphQL.Resolvers.Public do
  import Ecto.Query

  alias Hitbit.Repo
  alias Hitbit.Ecto.Helper
  alias Hitbit.Schemas.{User, Post}

  def sign_up(data, _resolution) do
    %User{}
    |> User.changeset(data)
    |> Repo.insert()
    |> Helper.id_resolver()
  end

  def authenticate(data, _resolution) do
    case Hitbit.Auth.attempt(data) do
      {:ok, token} -> {:ok, token}
      :error -> {:error, :unauthorized}
    end
  end

  def latest_posts(%{limit: limit}, _resolution) do
    # TODO: upper bound
    query =
      from post in Post,
        order_by: [desc: post.inserted_at],
        limit: ^limit

    {:ok, Repo.all(query)}
  end
end

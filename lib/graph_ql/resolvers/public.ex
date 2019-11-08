defmodule GraphQL.Resolvers.Public do
  import Ecto.Query

  alias Hitbit.Repo
  alias Hitbit.Auth
  alias Hitbit.Ecto.Helper
  alias Hitbit.Schemas.{User, Post}

  def sign_up(data, _resolution) do
    %User{}
    |> User.changeset(data)
    |> Repo.insert()
    |> Helper.id_resolver()
  end

  def login(data, _resolution) do
    case Auth.login(data) do
      {:ok, auth} ->
        {:ok, auth}

      :error ->
        {:error, :unauthorized}
    end
  end

  def refresh(%{token: token}, _resolution) do
    case Auth.refresh(token) do
      {:ok, auth} ->
        {:ok, auth}

      :error ->
        {:error, :unauthorized}
    end
  end

  def logout(%{token: token}, _resolution) do
    case Auth.revoke(token) do
      :ok ->
        {:ok, true}

      :error ->
        {:error, :unauthorized}
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

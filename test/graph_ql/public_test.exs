defmodule GraphQL.PublicTest do
  use HitbitWeb.ConnCase

  alias Hitbit.Repo
  alias Hitbit.Schemas.Post

  defp sign_up_query(data) do
    """
    mutation {
      signUp(
        username: "#{data.username}",
        email: "#{data.email}",
        password: "#{data.password}"
      )
    }
    """
  end

  describe "sign up" do
    setup _context do
      Utils.create_default_user()
    end

    test "new user", %{conn: conn} do
      %{"data" => data} =
        gql conn,
            sign_up_query(%{
              username: "new-user",
              email: "new-user@hitbit.app",
              password: "new-user-password"
            })

      assert %{"signUp" => id} = data
      assert is_binary(id)
    end

    test "duplicate username", %{conn: conn, user: user} do
      %{"errors" => [error]} =
        gql conn,
            sign_up_query(%{
              username: user.username,
              email: "new-user@hitbit.app",
              password: "new-user-password"
            })

      assert error["message"] ==
               "username '#{user.username}' has already been taken"
    end

    test "duplicate email", %{conn: conn, user: user} do
      %{"errors" => [error]} =
        gql conn,
            sign_up_query(%{
              username: "new-user",
              email: user.email,
              password: "new-user-password"
            })

      assert error["message"] ==
               "email '#{user.email}' has already been taken"
    end
  end

  defp login_query(data) do
    """
    mutation {
      login(
        email: "#{data.email}",
        password: "#{data.password}"
      )
    }
    """
  end

  describe "login" do
    setup _context do
      Utils.create_default_user()
    end

    test "successfully", %{conn: conn, user: user} do
      %{"data" => data} =
        gql conn,
            login_query(%{
              email: user.email,
              password: user.password
            })

      assert is_binary(data["login"])
    end

    test "empty password", %{conn: conn, user: user} do
      %{"errors" => [error]} =
        gql conn,
            login_query(%{
              email: user.email,
              password: ""
            })

      assert error["message"] == "unauthorized"
    end
  end

  defp post_data(url, author) do
    %{
      audio_url: url,
      author_user_id: author.id,
      inserted_at: Utils.utc_now(),
      updated_at: Utils.utc_now()
    }
  end

  defp create_posts(_context) do
    [user: author] = Utils.create_default_user()

    Repo.insert_all(Post, [
      post_data("http://url1", author),
      post_data("http://url2", author),
      post_data("http://url3", author)
    ])

    :ok
  end

  describe "latest posts" do
    setup [:create_posts]

    test "get", %{conn: conn} do
      %{"data" => data} =
        gql conn, """
        {
          latestPosts(limit: 3) {
            id, audioUrl
          }
        }
        """

      assert length(data["latestPosts"]) == 3

      for post <- data["latestPosts"] do
        assert is_binary(post["id"])
      end
    end
  end
end

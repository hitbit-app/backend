defmodule GraphQL.UserTest do
  use HitbitWeb.ConnCase

  describe "user info" do
    setup _context do
      Utils.create_default_user()
    end

    test "unauthorized", %{conn: conn} do
      %{"errors" => [error]} = gql conn, "{ userInfo { id } }"

      assert error["message"] == "unauthorized"
    end

    test "self id", %{conn: conn, user: user} do
      %{"data" => data} = gql conn, user, "{ userInfo { id } }"

      assert data["userInfo"]["id"] == user.id
    end
  end

  describe "insert post" do
    setup _context do
      Utils.create_default_user()
    end

    test "unauthorized", %{conn: conn} do
      %{"errors" => [error]} =
        gql conn, """
        mutation {
          insertPost(audioUrl: "test")
        }
        """

      assert error["message"] == "unauthorized"
    end

    test "invalid URL", %{conn: conn, user: user} do
      %{"errors" => [error]} =
        gql conn, user, """
        mutation {
          insertPost(audioUrl: "test")
        }
        """

      assert error["message"] == "audioUrl is invalid"
    end

    test "successfully", %{conn: conn, user: user} do
      %{"data" => data} =
        gql conn, user, """
        mutation {
          insertPost(audioUrl: "http://test")
        }
        """

      assert %{"insertPost" => id} = data
      assert is_binary(id)
    end
  end

  defp create_posts(_context) do
    user_1 =
      Utils.create_user(%{
        username: "user-1",
        email: "user-1@hitbit.app",
        password: "user-1-password"
      })

    user_2 =
      Utils.create_user(%{
        username: "user-2",
        email: "user-2@hitbit.app",
        password: "user-2-password"
      })

    post_1 =
      Utils.create_post(%{
        url: "http://post-1",
        author: user_1
      })

    post_2 =
      Utils.create_post(%{
        url: "http://post-2",
        author: user_2
      })

    [users: [user_1, user_2], posts: [post_1, post_2]]
  end

  describe "insert comment" do
    setup [:create_posts]

    test "successfully", context do
      post_1 = Enum.at(context.posts, 0)
      user_2 = Enum.at(context.users, 1)

      %{"data" => data} =
        gql context.conn, user_2, """
        mutation {
          insertComment(
            postId: "#{post_1.id}",
            text: "hello, world"
          )
        }
        """

      assert %{"insertComment" => id} = data
      assert is_binary(id)
    end
  end

  defp create_comments(context) do
    [users: users, posts: posts] = create_posts(context)

    comment_1 =
      Utils.create_comment(%{
        post: Enum.at(posts, 0),
        author: Enum.at(users, 1),
        text: "hello, world"
      })

    [users: users, posts: posts, comments: [comment_1]]
  end

  describe "insert reply" do
    setup [:create_comments]

    test "successfully", context do
      user_1 = Enum.at(context.users, 0)
      comment = Enum.at(context.comments, 0)

      %{"data" => data} =
        gql context.conn, user_1, """
        mutation {
          insertReply(
            commentId: "#{comment.id}",
            text: "I'm a reply"
          )
        }
        """

      assert %{"insertReply" => id} = data
      assert is_binary(id)
    end
  end
end

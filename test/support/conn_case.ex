defmodule HitBitWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      alias HitBitWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint HitBitWeb.Endpoint
      @gql_api "/api"

      defp gql(conn, query) do
        conn
        |> post(@gql_api, %{query: query})
        |> json_response(200)
      end

      defp gql(conn, user, query) do
        conn
        |> auth(user)
        |> gql(query)
      end

      defp auth(conn, user) do
        %{"data" => %{"login" => token}} =
          gql conn,
              """
              mutation {
                login(
                  email: "#{user.email}"
                  password: "#{user.password}"
                )
              }
              """

        put_req_header(conn, "authorization", "Bearer #{token}")
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HitBit.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HitBit.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

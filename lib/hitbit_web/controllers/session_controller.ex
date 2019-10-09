defmodule HitBitWeb.SessionController do
  use HitBitWeb, :controller

  defp frontend_origin do
    Application.get_env(:hitbit, __MODULE__)
    |> Keyword.get(:frontend_origin)
  end

  defp gql_endpoint do
    Application.get_env(:hitbit, __MODULE__, [])
    |> Keyword.get(:gql_endpoint, HitBitWeb.Endpoint.url())
  end

  def call(conn, action) when is_atom(action) do
    conn =
      conn
      |> put_resp_header("content-type", "text/html")
      |> put_resp_header("x-frame-options", "allow-from #{frontend_origin()}")

    apply(__MODULE__, action, [conn, conn.params])
  end

  def index(conn, _params) do
    bindings = [
      frontend_origin: frontend_origin(),
      gql_endpoint: gql_endpoint()
    ]

    resp_body =
      :code.priv_dir(:hitbit)
      |> Path.join("html")
      |> Path.join("session-container.eex")
      |> EEx.eval_file(bindings)

    resp(conn, 200, resp_body)
  end
end

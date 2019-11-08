defmodule HitbitWeb.AuthController do
  use HitbitWeb, :controller

  alias Hitbit.Auth

  defp unauthorized(conn) do
    conn
    |> put_status(401)
    |> json(%{"error" => "unauthorized"})
  end

  def login(conn, params) do
    with %{"email" => email, "password" => password} <- params,
         {:ok, auth} <- Auth.login(%{email: email, password: password}) do
      json(conn, auth)
    else
      _ -> unauthorized(conn)
    end
  end

  def refresh(conn, _params) do
    with {:ok, token} <- Auth.get_header_token(conn),
         {:ok, auth} <- Auth.refresh(token) do
      json(conn, auth)
    else
      _ -> unauthorized(conn)
    end
  end

  def logout(conn, _params) do
    with {:ok, token} <- Auth.get_header_token(conn),
         :ok <- Auth.revoke(token) do
      put_status(conn, 200)
    else
      _ -> unauthorized(conn)
    end
  end
end

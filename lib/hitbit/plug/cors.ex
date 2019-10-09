defmodule HitBit.Plug.CORS do
  @behaviour Plug

  import Plug.Conn

  def defaults do
    [
      origins: [],
      allowed_headers: [
        "authorization",
        "content-type"
      ],
      exposed_headers: [],
      max_age: 1_728_000,
      credentials: true,
      methods: [
        "GET",
        "PUT",
        "POST",
        "PATCH",
        "DELETE",
        "OPTIONS"
      ]
    ]
  end

  def init(opts) do
    config_opts = Application.get_env(:hitbit, __MODULE__, [])

    defaults()
    |> Keyword.merge(config_opts)
    |> Keyword.merge(opts)
  end

  def call(%Plug.Conn{method: "OPTIONS"} = conn, opts) do
    handle_cors(conn, opts, fn conn ->
      conn
      |> merge_preflight_headers(opts)
      |> send_resp(204, "")
      |> halt()
    end)
  end

  def call(%Plug.Conn{} = conn, opts) do
    handle_cors(conn, opts, & &1)
  end

  defp handle_cors(conn, opts, handle_preflight) do
    origin = conn |> get_req_header("origin") |> List.first()

    if allowed?(origin, opts[:origins]) do
      conn
      |> put_resp_header("access-control-allow-origin", origin)
      |> merge_cors_headers(opts)
      |> handle_preflight.()
    else
      conn
    end
  end

  defp allowed?(current, allowed) when is_list(allowed),
    do: Enum.any?(allowed, &allowed?(current, &1))

  defp allowed?(nil, _), do: false
  defp allowed?(_, "*"), do: true
  defp allowed?(current, allowed), do: current == allowed

  defp join(enum), do: Enum.join(enum, ",")

  defp merge_preflight_headers(conn, opts) do
    merge_resp_headers(conn, [
      {"access-control-allow-methods", opts[:methods] |> join()},
      {"access-control-allow-headers", opts[:allowed_headers] |> join()},
      {"access-control-max-age", opts[:max_age] |> to_string()}
    ])
  end

  defp merge_cors_headers(conn, opts) do
    merge_resp_headers(conn, [
      {"access-control-expose-headers", opts[:exposed_headers] |> join()},
      {"access-control-allow-credentials", opts[:credentials] |> to_string()}
    ])
  end
end

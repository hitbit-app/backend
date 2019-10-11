defmodule Hitbit.Mailgun do
  @content_type 'application/x-www-form-urlencoded'

  @http_opts [
    timeout: 5000
  ]

  @req_opts [
    sync: true,
    full_result: true,
    body_format: :string
  ]

  defp config_fetch!(key) do
    Application.get_env(:hitbit, __MODULE__, [])
    |> Keyword.fetch!(key)
  end

  defp endpoint do
    "https://api.mailgun.net/v3/#{config_fetch!(:domain)}/messages"
    |> to_charlist()
  end

  defp auth_header do
    auth_token =
      "api:#{config_fetch!(:api_key)}"
      |> Base.encode64(padding: false)
      |> to_charlist()

    {'authorization', 'Basic ' ++ auth_token}
  end

  def send(%{from: _, to: _, subject: _, text: _} = data) do
    body = URI.encode_query(data)
    http_request = {endpoint(), [auth_header()], @content_type, body}

    :httpc.request(:post, http_request, @http_opts, @req_opts)
  end
end

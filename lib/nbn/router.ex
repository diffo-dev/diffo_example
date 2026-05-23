# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Router do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NBN HTTP router. Serves the catalog endpoint and forwards `/mcp` to the
  AshAi MCP router (the externally-callable surface for the domain).

  Start with:

      Plug.Cowboy.http(DiffoExample.Nbn.Router, [], port: 4000)
  """
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  get "/catalog" do
    result = Jason.encode!(DiffoExample.Nbn.Catalog.list())

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, result)
  end

  forward "/mcp",
    to: AshAi.Mcp.Router,
    init_opts: [
      tools: true,
      otp_app: :diffo_example,
      protocol_version_statement: "2024-11-05"
    ]

  match _ do
    send_resp(conn, 404, "not found")
  end
end

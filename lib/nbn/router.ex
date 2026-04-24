# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Router do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NBN HTTP router. Handles the catalog endpoint directly and forwards
  all JSON API traffic to the AshJsonApi router.

  Start with:

      Plug.Cowboy.http(DiffoExample.Nbn.Router, [], port: 4000)
  """
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/vnd.api+json", "application/json"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  get "/catalog" do
    result = Jason.encode!(DiffoExample.Nbn.Catalog.list())

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, result)
  end

  forward "/", to: DiffoExample.Nbn.ApiRouter
end

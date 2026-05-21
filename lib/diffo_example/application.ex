# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        []
      else
        [
          {Task, &DiffoExample.Nbn.Initializer.init/0},
          {Plug.Cowboy, scheme: :http, plug: DiffoExample.Nbn.Router, options: [port: 4000]}
        ]
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: DiffoExample.Supervisor)
  end
end

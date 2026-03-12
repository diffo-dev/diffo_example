# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Repo do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Repo - persistance
  """

  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(_stack) do
    config = Application.get_env(:bolty, Bolt)
    Bolty.start_link(config)
  end
end

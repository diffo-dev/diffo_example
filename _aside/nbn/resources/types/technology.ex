# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule DiffoExample.Nbn.Technology do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Technology type for NBN domain
  """

  use Ash.Type.Enum,
    values: [:FTTP, :FTTN, :FTTB, :FTTC, :HFC, :FixedWireless, :Satellite]

  def default do
    :FTTP
  end
end

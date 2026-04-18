# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule DiffoExample.Nbn.Technology do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Technology type for NBN domain
  """

  require Ash.Type.NewType

  use Ash.Type.NewType,
    subtype_of: :atom,
    constraints: [one_of: technology()]

  def default do
    :FTTP
  end

  def technology do
    [:FTTP, :FTTN, :FTTB, :FTTC, :HFC, :FixedWireless, :Satellite]
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.UniValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  UniValue - AshTyped Struct for UNI Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.Technology

  jason do
    pick [:port, :encapsulation, :technology]
    compact true
  end

  outstanding do
    expect [:port, :encapsulation, :technology]
  end

  typed_struct do
    field :port, :integer, description: "the port of the UNI, assigned by the related NTD"

    field :encapsulation, :string, description: "the encapsulation of the UNI"

    field :technology, Technology, description: "the access technology type"
  end
end

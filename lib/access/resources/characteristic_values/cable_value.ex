# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.CableValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  CableValue - AshTyped Struct for Cable Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:name, :pairs, :length, :loss, :technology]
    compact true
  end

  outstanding do
    expect [:pairs, :loss]
  end

  typed_struct do
    field :name, :string, description: "the cable name"

    field :pairs, :integer, description: "the number of pairs in the cable"

    field :length, DiffoExample.Access.IntegerUnit, description: "the length of the cable"

    field :loss, DiffoExample.Access.FloatUnit, description: "the loss of the cable at 300kHz"

    field :technology, :atom, description: "the cable technology"
  end
end

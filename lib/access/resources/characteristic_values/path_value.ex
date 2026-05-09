# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.PathValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  PathValue - AshTyped Struct for Path Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:name, :sections, :length, :loss, :technology]
    compact true
  end

  outstanding do
    expect [:loss]
  end

  typed_struct do
    field :name, :string, description: "the cable name"

    field :sections, :integer,
      default: 0,
      constraints: [min: 0],
      description: "the number of sections in the path"

    field :length, DiffoExample.Access.IntegerUnit, description: "the length of the path"

    field :loss, DiffoExample.Access.FloatUnit, description: "the loss of the path at 300kHz"

    field :technology, :atom, description: "the path technology"
  end
end

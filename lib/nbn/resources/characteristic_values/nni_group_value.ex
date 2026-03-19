# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NniGroupValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NniGroupValue - AshTyped Struct for NNI Group Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:name, :location]
    compact(true)
  end

  outstanding do
    expect [:name, :location]
  end

  typed_struct do
    field :name, :string, description: "the NNI group name"

    field :location, :string, description: "the Point of Interconnect (PoI) location"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NniValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NniValue - AshTyped Struct for NNI Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:port_id, :capacity, :technology]
    compact(true)
  end

  outstanding do
    expect [:port_id, :capacity]
  end

  typed_struct do
    field :port_id, :string, description: "the NNI port identifier"

    field :capacity, :integer, description: "the NNI port capacity in Gbps"

    field :technology, :atom, description: "the NNI technology (:Ethernet, :Fibre)"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

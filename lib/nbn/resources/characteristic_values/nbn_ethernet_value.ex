# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NbnEthernetValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NbnEthernetValue - AshTyped Struct for NBN Ethernet Circuit Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:circuit_id, :speed, :technology]
    compact(true)
  end

  outstanding do
    expect [:circuit_id, :speed]
  end

  typed_struct do
    field :circuit_id, :string, description: "the unique NBN circuit identifier"

    field :speed, :integer, description: "the circuit download speed in Mbps"

    field :technology, :atom,
      description: "the access technology (:FTTP, :FTTN, :HFC, :Fixed_Wireless)"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

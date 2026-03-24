# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.PriValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NbnEthernetValue - AshTyped Struct for NBN Ethernet Access Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  @technologies [:FTTP, :FTTN, :FTTB, :FTTC, :HFC, :FixedWireless, :Satellite]

  jason do
    pick [:avcid, :uniid, :speed, :technology]
    compact(true)
  end

  outstanding do
    expect [:circuit_id, :speed]
  end

  typed_struct do
    field :avcid, :string, description: "the avcid from the owne Avc Resource"

    field :uniid, :string, description: "the uniid from the owned Uni Resource"

    field :speed, :integer, description: "the circuit download speed in Mbps"

    field :technology, :atom,
      description: "the access technology",
      constraints: [one_of: @technologies],
      default: :FTTP
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

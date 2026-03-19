# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.UniValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  UniValue - AshTyped Struct for UNI Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:vlan_id, :bandwidth_profile, :technology]
    compact(true)
  end

  outstanding do
    expect [:vlan_id, :technology]
  end

  typed_struct do
    field :vlan_id, :integer, description: "the VLAN ID for the UNI"

    field :bandwidth_profile, :string, description: "the bandwidth profile name for the UNI"

    field :technology, :atom,
      description: "the access technology (:FTTP, :FTTN, :HFC, :Fixed_Wireless)"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

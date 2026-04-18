# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.AggregateInterface do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  AggregateInterface - AshTyped Struct for AggregateInterface Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:name, :physical_interface, :physical_layer, :link_layer, :svlan_id, :vpi]
    compact(true)

    rename physical_interface: "physicalInterface",
           physical_layer: "physicalLayer",
           link_layer: "linkLayer",
           svlan_id: "svlanId",
           vpi: "VPI"
  end

  outstanding do
    expect [:name]
  end

  typed_struct do
    field :name, :string, description: "the name of the aggregate interface"

    field :physical_interface, :string,
      constraints: [match: ~r/OC-3 LR(-2)?|1000BASE-(L|E|Z)X/],
      description: "the aggregate interface physical interface type"

    field :physical_layer, :atom,
      constraints: [one_of: [:STM1, :GbE]],
      default: :GbE,
      description: "the aggregate interface physical layer standard"

    field :link_layer, :atom,
      constraints: [one_of: [:VP, :Q, :QinQ]],
      default: :QinQ,
      description: "the aggregate interface link layer standard"

    field :svlan_id, :integer,
      constraints: [min: 0, max: 4095],
      default: 0,
      description: "the aggregate interface svlan_id"

    field :vpi, :integer,
      constraints: [min: 0, max: 4095],
      default: 0,
      description: "the aggregate interface vpi"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

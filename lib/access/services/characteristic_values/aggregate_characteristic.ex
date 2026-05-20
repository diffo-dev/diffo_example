# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.AggregateCharacteristic do
  @moduledoc "Typed characteristic for an aggregate interface."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  resource do
    description "Typed characteristic carrying aggregate interface fields"
    plural_name :aggregate_characteristics
  end

  attributes do
    attribute :interface_name, :string, public?: true
    attribute :physical_interface, :string, public?: true
    attribute :physical_layer, :atom, public?: true
    attribute :link_layer, :atom, public?: true
    attribute :svlan_id, :integer, public?: true
    attribute :vpi, :integer, public?: true
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue,
              Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :interface_name, :physical_interface, :physical_layer, :link_layer, :svlan_id, :vpi]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:interface_name, :physical_interface, :physical_layer, :link_layer, :svlan_id, :vpi]
    end
  end

  preparations do
    prepare build(load: [:value])
  end

  jason do
    pick [:name, :value]
    compact true
  end
end

defmodule DiffoExample.Access.AggregateCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  typed_struct do
    field :interface_name, :string
    field :physical_interface, :string
    field :physical_layer, :atom
    field :link_layer, :atom
    field :svlan_id, :integer
    field :vpi, :integer
  end

  outstanding do
    expect [:interface_name]
  end

  jason do
    pick [:interface_name, :physical_interface, :physical_layer, :link_layer, :svlan_id, :vpi]
    compact true

    rename interface_name: "name",
           physical_interface: "physicalInterface",
           physical_layer: "physicalLayer",
           link_layer: "linkLayer",
           svlan_id: "svlanId",
           vpi: "VPI"
  end
end

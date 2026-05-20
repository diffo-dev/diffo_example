# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NniCharacteristic do
  @moduledoc "Typed characteristic for an NNI's port properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Typed characteristic carrying NNI port fields"
    plural_name :nni_characteristics
  end

  attributes do
    attribute :port_id, :string, public?: true
    attribute :capacity, :integer, public?: true
    attribute :technology, :atom, public?: true
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue,
              Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :port_id, :capacity, :technology]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:port_id, :capacity, :technology]
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

defmodule DiffoExample.Nbn.NniCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  typed_struct do
    field :port_id, :string
    field :capacity, :integer
    field :technology, :atom
  end

  outstanding do
    expect [:port_id, :capacity]
  end

  jason do
    pick [:port_id, :capacity, :technology]
    compact true
    rename port_id: "portId"
  end
end

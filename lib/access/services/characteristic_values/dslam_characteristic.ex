# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.DslamCharacteristic do
  @moduledoc "Typed characteristic for a DSLAM's identity."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  resource do
    description "Typed characteristic carrying DSLAM identity fields"
    plural_name :dslam_characteristics
  end

  actions do
    create :create do
      accept [:name, :device_name, :family, :model, :technology]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:device_name, :family, :model, :technology]
    end
  end

  attributes do
    attribute :device_name, :string, public?: true
    attribute :family, :atom, public?: true
    attribute :model, :string, public?: true
    attribute :technology, :atom, public?: true
  end

  calculations do
    calculate :value,
              Diffo.Type.CharacteristicValue,
              Diffo.Provider.Calculations.CharacteristicValue do
      public? true
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

defmodule DiffoExample.Access.DslamCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:device_name, :family, :model, :technology]
    compact true
    rename device_name: "name"
  end

  outstanding do
    expect [:device_name]
  end

  typed_struct do
    field :device_name, :string
    field :family, :atom
    field :model, :string
    field :technology, :atom
  end
end

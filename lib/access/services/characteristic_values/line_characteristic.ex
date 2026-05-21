# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.LineCharacteristic do
  @moduledoc "Typed characteristic for a DSL line's port properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  resource do
    description "Typed characteristic carrying DSL line port fields"
    plural_name :line_characteristics
  end

  actions do
    create :create do
      accept [:name, :port, :slot, :standard, :profile]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:port, :slot, :standard, :profile]
    end
  end

  attributes do
    attribute :port, :integer, public?: true
    attribute :slot, :integer, public?: true
    attribute :standard, :atom, public?: true
    attribute :profile, :string, public?: true
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

defmodule DiffoExample.Access.LineCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:port, :slot, :standard, :profile]
    compact true
  end

  outstanding do
    expect [:port, :slot, :profile]
  end

  typed_struct do
    field :port, :integer
    field :slot, :integer
    field :standard, :atom
    field :profile, :string
  end
end

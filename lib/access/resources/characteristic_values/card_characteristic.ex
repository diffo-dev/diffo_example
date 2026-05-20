# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.CardCharacteristic do
  @moduledoc "Typed characteristic for a Card's identity."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  resource do
    description "Typed characteristic carrying card identity fields"
    plural_name :card_characteristics
  end

  attributes do
    attribute :family, :atom, public?: true
    attribute :model, :string, public?: true
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
      accept [:name, :family, :model, :technology]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:family, :model, :technology]
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

defmodule DiffoExample.Access.CardCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  typed_struct do
    field :family, :atom
    field :model, :string
    field :technology, :atom
  end

  jason do
    pick [:family, :model, :technology]
    compact true
  end
end

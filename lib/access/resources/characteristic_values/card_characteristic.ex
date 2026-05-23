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

defmodule DiffoExample.Access.CardCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:family, :model, :technology]
    compact true
  end

  typed_struct do
    field :family, :atom
    field :model, :string
    field :technology, :atom
  end
end

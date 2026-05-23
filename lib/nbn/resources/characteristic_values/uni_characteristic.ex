# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.UniCharacteristic do
  @moduledoc "Typed characteristic for a UNI's port properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Typed characteristic carrying UNI port fields"
    plural_name :uni_characteristics
  end

  attributes do
    attribute :port, :integer, public?: true
    attribute :encapsulation, :string, public?: true
    attribute :technology, DiffoExample.Nbn.Technology, public?: true
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

defmodule DiffoExample.Nbn.UniCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.Technology

  jason do
    pick [:port, :encapsulation, :technology]
    compact true
  end

  outstanding do
    expect [:port, :encapsulation, :technology]
  end

  typed_struct do
    field :port, :integer
    field :encapsulation, :string
    field :technology, Technology
  end
end

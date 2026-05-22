# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.CvcCharacteristic do
  @moduledoc "Typed characteristic for a CVC's bandwidth properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Typed characteristic carrying CVC bandwidth fields"
    plural_name :cvc_characteristics
  end

  attributes do
    attribute :svlan, :integer, public?: true
    attribute :bandwidth, :integer, public?: true
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

defmodule DiffoExample.Nbn.CvcCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:svlan, :bandwidth]
    compact true
  end

  outstanding do
    expect [:svlan, :bandwidth]
  end

  typed_struct do
    field :svlan, :integer
    field :bandwidth, :integer
  end
end

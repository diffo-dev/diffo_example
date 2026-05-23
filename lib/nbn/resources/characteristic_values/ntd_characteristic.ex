# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NtdCharacteristic do
  @moduledoc "Typed characteristic for an NTD's device properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Typed characteristic carrying NTD device fields"
    plural_name :ntd_characteristics
  end

  attributes do
    attribute :model, :string, public?: true
    attribute :serial_number, :string, public?: true
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

defmodule DiffoExample.Nbn.NtdCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.Technology

  jason do
    pick [:model, :serial_number, :technology]
    compact true
  end

  outstanding do
    expect [:model, :serial_number]
  end

  typed_struct do
    field :model, :string
    field :serial_number, :string
    field :technology, Technology
  end
end

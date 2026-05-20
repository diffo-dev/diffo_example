# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NniGroupCharacteristic do
  @moduledoc "Typed characteristic for an NNI Group's identity."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Typed characteristic carrying NNI Group identity fields"
    plural_name :nni_group_characteristics
  end

  attributes do
    attribute :group_name, :string, public?: true
    attribute :location, :string, public?: true
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue,
              Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :group_name, :location]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:group_name, :location]
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

defmodule DiffoExample.Nbn.NniGroupCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  typed_struct do
    field :group_name, :string
    field :location, :string
  end

  outstanding do
    expect [:group_name, :location]
  end

  jason do
    pick [:group_name, :location]
    compact true
    rename group_name: "name"
  end
end

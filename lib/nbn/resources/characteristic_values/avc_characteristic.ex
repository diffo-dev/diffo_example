# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.AvcCharacteristic do
  @moduledoc "Typed characteristic for an AVC's circuit properties."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Typed characteristic carrying AVC circuit fields"
    plural_name :avc_characteristics
  end

  actions do
    create :create do
      accept [:name, :cvlan, :bandwidth_profile]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:cvlan, :bandwidth_profile]
    end
  end

  attributes do
    attribute :cvlan, :integer, public?: true
    attribute :bandwidth_profile, DiffoExample.Nbn.BandwidthProfile, public?: true
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

defmodule DiffoExample.Nbn.AvcCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.BandwidthProfile

  jason do
    pick [:cvlan, :bandwidth_profile]
    compact true
  end

  outstanding do
    expect [:cvlan, :bandwidth_profile]
  end

  typed_struct do
    field :cvlan, :integer
    field :bandwidth_profile, BandwidthProfile
  end
end

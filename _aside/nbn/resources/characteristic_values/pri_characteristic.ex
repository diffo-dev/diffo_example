# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.PriCharacteristic do
  @moduledoc "Typed characteristic for an NBN Ethernet access (PRI)."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Typed characteristic carrying NBN Ethernet access fields"
    plural_name :pri_characteristics
  end

  attributes do
    attribute :avcid, :string, public?: true
    attribute :uniid, :string, public?: true
    attribute :technology, DiffoExample.Nbn.Technology, public?: true
    attribute :bandwidth_profile, DiffoExample.Nbn.BandwidthProfile, public?: true
    attribute :speeds_downstream, :integer, public?: true
    attribute :speeds_upstream, :integer, public?: true
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue,
              DiffoExample.Nbn.PriCharacteristic.ValueCalculation do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :avcid, :uniid, :technology, :bandwidth_profile, :speeds_downstream, :speeds_upstream]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:avcid, :uniid, :technology, :bandwidth_profile, :speeds_downstream, :speeds_upstream]
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

defmodule DiffoExample.Nbn.PriCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.Technology
  alias DiffoExample.Nbn.BandwidthProfile

  typed_struct do
    field :avcid, :string
    field :uniid, :string
    field :technology, Technology
    field :bandwidth_profile, BandwidthProfile
    field :speeds, :map
  end

  outstanding do
    expect [:avcid, :uniid, :technology, :bandwidth_profile, :speeds]
  end

  jason do
    pick [:avcid, :uniid, :technology, :bandwidth_profile, :speeds]
    compact true
    rename avcid: "AVCID", uniid: "UNIID", bandwidth_profile: "bandwidthProfile"
  end
end

defmodule DiffoExample.Nbn.PriCharacteristic.ValueCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  alias DiffoExample.Nbn.PriCharacteristic

  @impl true
  def load(_, _, _), do: []

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn r ->
      %PriCharacteristic.Value{
        avcid: r.avcid,
        uniid: r.uniid,
        technology: r.technology,
        bandwidth_profile: r.bandwidth_profile,
        speeds:
          if r.speeds_downstream do
            %{downstream: r.speeds_downstream, upstream: r.speeds_upstream, units: "Mbps"}
          end
      }
    end)
  end
end

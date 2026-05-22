# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.CircuitCharacteristic do
  @moduledoc "Typed characteristic for a DSL circuit."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  alias DiffoExample.Access.CharacteristicChanges

  resource do
    description "Typed characteristic carrying DSL circuit fields"
    plural_name :circuit_characteristics
  end

  actions do
    update :update do
      accept [:circuit_id, :cvlan_id, :vci, :encapsulation]
      argument :bandwidth_profile, :term, allow_nil?: true

      change fn changeset, _ ->
        CharacteristicChanges.set_bandwidth_profile(
          changeset,
          :bandwidth_profile,
          :bp_downstream,
          :bp_upstream,
          :bp_units
        )
      end
    end
  end

  attributes do
    attribute :circuit_id, :string, public?: true
    attribute :cvlan_id, :integer, public?: true
    attribute :vci, :integer, public?: true
    attribute :encapsulation, :atom, public?: true
    attribute :bp_downstream, :integer, public?: true
    attribute :bp_upstream, :integer, public?: true
    attribute :bp_units, :atom, public?: true
  end

  calculations do
    calculate :value,
              Diffo.Type.CharacteristicValue,
              DiffoExample.Access.CircuitCharacteristic.ValueCalculation do
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

defmodule DiffoExample.Access.CircuitCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Access.BandwidthProfile

  jason do
    pick [:circuit_id, :cvlan_id, :vci, :encapsulation, :bandwidth_profile]
    compact true
    rename circuit_id: "circuitId", vci: "VCI", bandwidth_profile: "bandwidthProfile"
  end

  outstanding do
    expect [:circuit_id]
  end

  typed_struct do
    field :circuit_id, :string
    field :cvlan_id, :integer
    field :vci, :integer
    field :encapsulation, :atom
    field :bandwidth_profile, BandwidthProfile
  end
end

defmodule DiffoExample.Access.CircuitCharacteristic.ValueCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  alias DiffoExample.Access.BandwidthProfile
  alias DiffoExample.Access.CircuitCharacteristic

  @impl true
  def load(_, _, _), do: []

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn r ->
      %CircuitCharacteristic.Value{
        circuit_id: r.circuit_id,
        cvlan_id: r.cvlan_id,
        vci: r.vci,
        encapsulation: r.encapsulation,
        bandwidth_profile:
          if r.bp_downstream do
            %BandwidthProfile{
              downstream: r.bp_downstream,
              upstream: r.bp_upstream,
              units: r.bp_units || :Mbps
            }
          end
      }
    end)
  end
end

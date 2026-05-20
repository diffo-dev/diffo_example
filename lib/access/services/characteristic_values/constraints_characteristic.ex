# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.ConstraintsCharacteristic do
  @moduledoc "Typed characteristic for DSL service constraints."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Access

  alias DiffoExample.Access.CharacteristicChanges

  resource do
    description "Typed characteristic carrying service constraint fields"
    plural_name :constraints_characteristics
  end

  attributes do
    attribute :max_latency, :integer, public?: true
    attribute :mp_downstream, :integer, public?: true
    attribute :mp_upstream, :integer, public?: true
    attribute :mp_units, :atom, public?: true
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue,
              DiffoExample.Access.ConstraintsCharacteristic.ValueCalculation do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :max_latency, :mp_downstream, :mp_upstream, :mp_units]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:max_latency]
      argument :min_profile, :term, allow_nil?: true

      change fn changeset, _ ->
        CharacteristicChanges.set_bandwidth_profile(
          changeset,
          :min_profile,
          :mp_downstream,
          :mp_upstream,
          :mp_units
        )
      end
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

defmodule DiffoExample.Access.ConstraintsCharacteristic.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Access.BandwidthProfile

  typed_struct do
    field :max_latency, :integer
    field :min_profile, BandwidthProfile
  end

  outstanding do
    expect [:max_latency, :min_profile]
  end

  jason do
    pick [:max_latency, :min_profile]
    compact true
    rename max_latency: "maxLatency", min_profile: "minProfile"
  end
end

defmodule DiffoExample.Access.ConstraintsCharacteristic.ValueCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  alias DiffoExample.Access.BandwidthProfile
  alias DiffoExample.Access.ConstraintsCharacteristic

  @impl true
  def load(_, _, _), do: []

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn r ->
      %ConstraintsCharacteristic.Value{
        max_latency: r.max_latency,
        min_profile:
          if r.mp_downstream do
            %BandwidthProfile{
              downstream: r.mp_downstream,
              upstream: r.mp_upstream,
              units: r.mp_units || :Mbps
            }
          end
      }
    end)
  end
end

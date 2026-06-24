# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.CvcMetrics do
  @moduledoc """
  Local metrics characteristic for a CVC — `avcs_count` and
  `avcs_total_bandwidth` aggregated live across the AVCs the CVC has
  assigned a cvlan to. Not inheritable.
  """
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Live metrics for a CVC — count and total downstream bandwidth across its assigned AVCs"
    plural_name :cvc_metrics
  end

  calculations do
    calculate :value,
              Diffo.Type.CharacteristicValue,
              DiffoExample.Nbn.CvcMetrics.ValueCalculation do
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

defmodule DiffoExample.Nbn.CvcMetrics.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:avcs_count, :avcs_total_bandwidth]
    compact true
    rename avcs_count: "avcsCount", avcs_total_bandwidth: "avcsTotalBandwidth"
  end

  typed_struct do
    field :avcs_count, :integer
    field :avcs_total_bandwidth, :integer
  end
end

defmodule DiffoExample.Nbn.CvcMetrics.ValueCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  alias DiffoExample.Nbn.AvcCharacteristic
  alias DiffoExample.Nbn.BandwidthProfile
  alias DiffoExample.Nbn.CvcMetrics

  @impl true
  def load(_, _, _), do: []

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn r ->
      # AVCs the CVC has assigned a cvlan to live on the target side of
      # outgoing AssignmentRelationships sourced from this CVC's :cvlan
      # pool. Filter by `thing` (the pool's thing name) rather than `alias`
      # — alias is the consumer's slot name and may be unset.
      avc_ids =
        Diffo.Provider.AssignmentRelationship
        |> Ash.Query.filter_input(source_id: r.instance_id, thing: :cvlan)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(& &1.target_id)

      avcs =
        Enum.flat_map(avc_ids, fn id ->
          AvcCharacteristic
          |> Ash.Query.filter_input(instance_id: id)
          |> Ash.read!()
        end)

      %CvcMetrics.Value{
        avcs_count: length(avcs),
        avcs_total_bandwidth:
          Enum.reduce(avcs, 0, fn avc, acc ->
            acc + BandwidthProfile.downstream(avc.bandwidth_profile)
          end)
      }
    end)
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NniGroupMetrics do
  @moduledoc """
  Local metrics characteristic for an NNI Group — demand-side aggregates
  across assigned CVCs (`cvcs_count`, `cvcs_total_bandwidth`), capacity-side
  aggregates across comprised NNIs (`nnis_count`, `nnis_total_bandwidth`),
  and the derived `utilization = cvcs_total_bandwidth / nnis_total_bandwidth`.

  Expected `utilization` range 0–1 under normal provisioning; >1 indicates
  deliberate oversubscription. Not inheritable.
  """
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: DiffoExample.Nbn

  resource do
    description "Live metrics for an NNI Group — demand from CVCs, capacity from NNIs, and utilization"
    plural_name :nni_group_metrics
  end

  calculations do
    calculate :value,
              Diffo.Type.CharacteristicValue,
              DiffoExample.Nbn.NniGroupMetrics.ValueCalculation do
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

defmodule DiffoExample.Nbn.NniGroupMetrics.Value do
  @moduledoc false
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [
      :cvcs_count,
      :cvcs_total_bandwidth,
      :nnis_count,
      :nnis_total_bandwidth,
      :utilization
    ]

    compact true

    rename cvcs_count: "cvcsCount",
           cvcs_total_bandwidth: "cvcsTotalBandwidth",
           nnis_count: "nnisCount",
           nnis_total_bandwidth: "nnisTotalBandwidth"
  end

  typed_struct do
    field :cvcs_count, :integer
    field :cvcs_total_bandwidth, :integer
    field :nnis_count, :integer
    field :nnis_total_bandwidth, :integer
    field :utilization, :float
  end
end

defmodule DiffoExample.Nbn.NniGroupMetrics.ValueCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  alias DiffoExample.Nbn.CvcCharacteristic
  alias DiffoExample.Nbn.NniCharacteristic
  alias DiffoExample.Nbn.NniGroupMetrics

  @impl true
  def load(_, _, _), do: []

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn r ->
      {cvcs_count, cvcs_total_bandwidth} = cvc_aggregates(r.instance_id)
      {nnis_count, nnis_total_bandwidth} = nni_aggregates(r.instance_id)

      %NniGroupMetrics.Value{
        cvcs_count: cvcs_count,
        cvcs_total_bandwidth: cvcs_total_bandwidth,
        nnis_count: nnis_count,
        nnis_total_bandwidth: nnis_total_bandwidth,
        utilization: utilization(cvcs_total_bandwidth, nnis_total_bandwidth)
      }
    end)
  end

  # Demand: CVCs the NNI Group has assigned an svlan to live on the target
  # side of outgoing AssignmentRelationships sourced from the group's :svlan
  # pool. Filter by `thing` (the pool's thing name) rather than `alias` —
  # alias is the consumer's slot name and may be unset.
  defp cvc_aggregates(nni_group_id) do
    cvc_ids =
      Diffo.Provider.AssignmentRelationship
      |> Ash.Query.filter_input(source_id: nni_group_id, thing: :svlan)
      |> Ash.read!(domain: Diffo.Provider)
      |> Enum.map(& &1.target_id)

    cvcs =
      Enum.flat_map(cvc_ids, fn id ->
        CvcCharacteristic
        |> Ash.Query.filter_input(instance_id: id)
        |> Ash.read!()
      end)

    {length(cvcs), Enum.reduce(cvcs, 0, fn cvc, acc -> acc + (cvc.bandwidth || 0) end)}
  end

  # Capacity: NNIs the NNI Group comprises live on the target side of
  # outgoing :contains Relationships sourced from the group. Relationships
  # (not DefinedSimpleRelationships) carry the relate-action's TMF
  # source/target/type/alias surface.
  defp nni_aggregates(nni_group_id) do
    nni_ids =
      Diffo.Provider.Relationship
      |> Ash.Query.filter_input(source_id: nni_group_id, type: :contains)
      |> Ash.read!(domain: Diffo.Provider)
      |> Enum.map(& &1.target_id)

    nnis =
      Enum.flat_map(nni_ids, fn id ->
        NniCharacteristic
        |> Ash.Query.filter_input(instance_id: id)
        |> Ash.read!()
      end)

    {length(nnis), Enum.reduce(nnis, 0, fn nni, acc -> acc + (nni.capacity || 0) end)}
  end

  defp utilization(_demand, capacity) when capacity in [nil, 0], do: 0.0
  defp utilization(demand, capacity), do: demand / capacity
end

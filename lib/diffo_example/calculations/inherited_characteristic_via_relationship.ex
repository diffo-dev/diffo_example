# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Calculations.InheritedCharacteristicViaRelationship do
  @moduledoc """
  Brings up typed characteristic values from target instances reached via
  forward `Diffo.Provider.Relationship` edges (source → target), optionally
  filtered by `type:` and/or `alias:`.

  Sibling to `InheritedCharacteristicViaAssignment`, which performs the
  analogous traversal over `AssignmentRelationship` edges. Pick the right
  calc by the kind of edge being traversed — relationship vs. assignment.

  Use this when the edge between the consuming instance and the target was
  created by a `:relate` action (a `Provider.Relationship` record). Use
  `InheritedCharacteristicViaAssignment` when the edge was created by the
  Assigner (an `AssignmentRelationship` record).

  Local-to-this-repo for now. Worth yarning upstream alongside the
  assignment variant as a pair of provider-side calcs.

  ## Options

  - `characteristic_module:` *(required)* — the typed characteristic Ash
    resource on the final source (e.g. `NniCharacteristic`). The calc
    queries this resource by `instance_id` and returns the `.value`.
  - `type:` *(optional)* — filter relationships by type atom (e.g. `:contains`).
  - `alias:` *(optional)* — filter relationships by alias atom (e.g. `:avc`).
  - `then_via:` *(optional)* — list of consumer-alias atoms to walk back
    via `AssignmentRelationship` **after** the relationship hop. Each step
    walks back through the target's incoming assignments (`target_id +
    alias` identity, so each step has cardinality ≤1). Aliases name the
    upstream related resource each consumer is part of. Use this for mixed
    paths — one relationship hop followed by one or more assignment hops
    — e.g. PRI's `:cvc` bring-up: `:circuit` owns relationship, then `:cvc`
    assignment back to the CVC.
  - `singular?:` *(optional, default `false`)* — unwrap to a single value
    when the consumer expects a 1-cardinality result (e.g. PRI's `:avc` or
    `:uni` aliased owns-relationship). Declare the calc's return type as
    `:map` (rather than `{:array, :map}`) when using this option.

  ## Examples

      # NniGroup brings up the typed characteristic of every NNI it
      # comprises — forward traversal of :contains relationships, returns
      # a list of NniCharacteristic values.
      calculate :nnis, {:array, :map},
                {DiffoExample.Calculations.InheritedCharacteristicViaRelationship,
                 [type: :contains, characteristic_module: NniCharacteristic]}

      # PRI brings up the singular AVC it owns — PRI calls this related
      # resource :circuit (its domain role), set as the alias on PRI's
      # owns relationship.
      calculate :avc, :map,
                {DiffoExample.Calculations.InheritedCharacteristicViaRelationship,
                 [alias: :circuit, characteristic_module: AvcCharacteristic, singular?: true]}

      # PRI brings up the singular CVC two-hop — :circuit owns relationship
      # from PRI to AVC, then back via the AVC's :cvc consumer-alias
      # assignment from CVC.
      calculate :cvc, :map,
                {DiffoExample.Calculations.InheritedCharacteristicViaRelationship,
                 [alias: :circuit, then_via: [:cvc],
                  characteristic_module: CvcCharacteristic, singular?: true]}
  """
  use Ash.Resource.Calculation
  require Ash.Query

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    characteristic_module = Keyword.fetch!(opts, :characteristic_module)
    type_filter = Keyword.get(opts, :type)
    alias_filter = Keyword.get(opts, :alias)
    then_via = Keyword.get(opts, :then_via, [])
    singular? = Keyword.get(opts, :singular?, false)

    Enum.map(records, fn record ->
      target_ids =
        Diffo.Provider.Relationship
        |> filter_relationships(record.id, type_filter, alias_filter)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(& &1.target_id)

      final_ids = walk_assignments(target_ids, then_via)

      values =
        Enum.flat_map(final_ids, fn id ->
          characteristic_module
          |> Ash.Query.filter_input(instance_id: id)
          |> Ash.Query.load(:value)
          |> Ash.read!()
          |> Enum.map(& &1.value)
        end)

      if singular?, do: List.first(values), else: values
    end)
  end

  # Walks back through incoming `AssignmentRelationship` records for each
  # id, following `target_id + alias` (identity, ≤1 source per step).
  defp walk_assignments(ids, []), do: ids

  defp walk_assignments(ids, [alias_step | rest]) do
    next_ids =
      Enum.flat_map(ids, fn id ->
        Diffo.Provider.AssignmentRelationship
        |> Ash.Query.filter_input(target_id: id, alias: alias_step)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(& &1.source_id)
      end)

    walk_assignments(next_ids, rest)
  end

  defp filter_relationships(query, source_id, nil, nil),
    do: Ash.Query.filter_input(query, source_id: source_id)

  defp filter_relationships(query, source_id, type, nil),
    do: Ash.Query.filter_input(query, source_id: source_id, type: type)

  defp filter_relationships(query, source_id, nil, alias_name),
    do: Ash.Query.filter_input(query, source_id: source_id, alias: alias_name)

  defp filter_relationships(query, source_id, type, alias_name),
    do: Ash.Query.filter_input(query, source_id: source_id, type: type, alias: alias_name)
end

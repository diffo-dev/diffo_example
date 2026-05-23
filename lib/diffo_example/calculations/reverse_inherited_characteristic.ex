# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Calculations.ReverseInheritedCharacteristic do
  @moduledoc """
  Brings up typed characteristic values from instances this one has
  assigned to — the reverse of inheritance.

  `InheritedCharacteristic` is the conventional direction: the assignee
  inherits its characteristic from its assigner (you inherit from your
  parents). This is the reverse: the assigner brings up the characteristic
  of every assignee it's connected to (insanity is hereditary — you get
  it from your kids).

  Traverses OUTGOING `AssignmentRelationship` records (this instance as
  source) optionally filtered by alias, then reads the typed characteristic
  on each assignee.

  Useful when the assigner wants to compose its assignees into its own
  view — e.g. a shelf bringing up the cards it has assigned slots to,
  ordered by slot number.

  Worth yarning upstream alongside `inherited_characteristic` as a pair
  of diffo-side DSL declarations.

  ## Options

  - `characteristic_module:` *(required)* — the typed characteristic Ash
    resource on each assignee (e.g. `CardCharacteristic`).
  - `alias:` *(optional)* — filter outgoing assignments by alias (the
    assignee's slot name). Use when every consumer follows the same
    aliasing convention.
  - `thing:` *(optional)* — filter outgoing assignments by `thing` (the
    pool's thing name, e.g. `:slot`, `:port`). Always set from the pool
    DSL declaration, so this is more robust than `alias:` when consumers
    don't reliably name their slots. See `[[assignment-direction-asymmetry]]`.

  Specify either `alias:` or `thing:` (or both); omitting both includes
  every outgoing assignment from this instance.

  ## Examples

      # Shelf brings up the card characteristic from every card it's
      # assigned a slot to, ordered by slot number. Cards-as-assignees
      # name their slot :slot when requesting.
      calculate :cards, {:array, :map},
                {DiffoExample.Calculations.ReverseInheritedCharacteristic,
                 [alias: :slot, characteristic_module: CardCharacteristic]}

      # NTD brings up the UNI characteristic from every UNI it's assigned
      # a port to. The UNIs may not have set an alias on their request,
      # so filter by `thing` from the :ports pool declaration.
      calculate :unis, {:array, :map},
                {DiffoExample.Calculations.ReverseInheritedCharacteristic,
                 [thing: :port, characteristic_module: UniCharacteristic]}
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    alias_filter = Keyword.get(opts, :alias)
    thing_filter = Keyword.get(opts, :thing)
    characteristic_module = Keyword.fetch!(opts, :characteristic_module)

    Enum.map(records, fn record ->
      assignments =
        Diffo.Provider.AssignmentRelationship
        |> filter_outgoing(record.id, alias_filter, thing_filter)
        |> Ash.Query.sort(value: :asc)
        |> Ash.read!(domain: Diffo.Provider)

      Enum.flat_map(assignments, fn assignment ->
        characteristic_module
        |> Ash.Query.filter_input(instance_id: assignment.target_id)
        |> Ash.Query.load(:value)
        |> Ash.read!()
        |> Enum.map(& &1.value)
      end)
    end)
  end

  defp filter_outgoing(query, source_id, nil, nil),
    do: Ash.Query.filter_input(query, source_id: source_id)

  defp filter_outgoing(query, source_id, alias_filter, nil),
    do: Ash.Query.filter_input(query, source_id: source_id, alias: alias_filter)

  defp filter_outgoing(query, source_id, nil, thing_filter),
    do: Ash.Query.filter_input(query, source_id: source_id, thing: thing_filter)

  defp filter_outgoing(query, source_id, alias_filter, thing_filter),
    do:
      Ash.Query.filter_input(query,
        source_id: source_id,
        alias: alias_filter,
        thing: thing_filter
      )
end

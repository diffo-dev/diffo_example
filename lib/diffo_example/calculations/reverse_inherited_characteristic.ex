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

  - `alias:` *(optional)* — filter outgoing assignments by alias (the
    assignee's slot name). When omitted, all outgoing assignments are
    included.
  - `characteristic_module:` *(required)* — the typed characteristic Ash
    resource on each assignee (e.g. `CardCharacteristic`).

  ## Example

      # Shelf brings up the card characteristic from every card it's
      # assigned a slot to, ordered by slot number.
      calculate :cards, {:array, :map},
                {DiffoExample.Calculations.ReverseInheritedCharacteristic,
                 [alias: :slot, characteristic_module: CardCharacteristic]}
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    alias_filter = Keyword.get(opts, :alias)
    characteristic_module = Keyword.fetch!(opts, :characteristic_module)

    Enum.map(records, fn record ->
      assignments =
        Diffo.Provider.AssignmentRelationship
        |> filter_outgoing(record.id, alias_filter)
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

  defp filter_outgoing(query, source_id, nil),
    do: query |> Ash.Query.filter_input(source_id: source_id)

  defp filter_outgoing(query, source_id, alias_filter),
    do: query |> Ash.Query.filter_input(source_id: source_id, alias: alias_filter)
end

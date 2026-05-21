# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Calculations.InheritedCharacteristic do
  @moduledoc """
  Brings up a typed characteristic value from an assignment-source instance.

  Mirrors the shape of `Diffo.Provider.Calculations.InheritedPlace` and
  `Diffo.Provider.Calculations.InheritedParty` — traverses
  `AssignmentRelationship` by alias to reach source instances, then queries
  the typed characteristic resource on each source and returns its `.value`.

  Local-to-this-repo for now. Worth yarning upstream as a diffo-side
  `inherited_characteristic` DSL declaration backed by a
  `Diffo.Provider.Calculations.InheritedCharacteristic` calc, sitting
  alongside the existing inherited-place and inherited-party machinery.

  ## Options

  - `via:` *(required)* — list of alias atoms naming the assignment chain
    from this instance back to the source whose characteristic we want.
    Each step filters `AssignmentRelationship` by `target_id` and `alias`,
    then follows `source_id` to the next set of instances. The aliases are
    the assignee's slot names, supplied when the assignment is made.
  - `characteristic_module:` *(required)* — the typed characteristic Ash
    resource on the final source (e.g. `ShelfCharacteristic`). The calc
    queries this resource by `instance_id` and returns the `.value`.

  ## Example

      # Card brings up its shelf's typed characteristic via the slot
      # assignment the shelf made to it (alias :slot on the incoming
      # AssignmentRelationship).
      calculate :shelf, :map,
                {DiffoExample.Calculations.InheritedCharacteristic,
                 [via: [:slot], characteristic_module: ShelfCharacteristic]}

      # Path brings up the same via a two-hop chain — port-then-slot.
      calculate :shelf, :map,
                {DiffoExample.Calculations.InheritedCharacteristic,
                 [via: [:port, :slot], characteristic_module: ShelfCharacteristic]}
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    via = Keyword.fetch!(opts, :via)
    characteristic_module = Keyword.fetch!(opts, :characteristic_module)

    Enum.map(records, fn record ->
      final_ids =
        Enum.reduce(via, [record.id], fn alias_step, ids ->
          Enum.flat_map(ids, fn id ->
            Diffo.Provider.AssignmentRelationship
            |> Ash.Query.filter_input(target_id: id, alias: alias_step)
            |> Ash.read!(domain: Diffo.Provider)
            |> Enum.map(& &1.source_id)
          end)
        end)

      Enum.flat_map(final_ids, fn id ->
        characteristic_module
        |> Ash.Query.filter_input(instance_id: id)
        |> Ash.Query.load(:value)
        |> Ash.read!()
        |> Enum.map(& &1.value)
      end)
    end)
  end
end

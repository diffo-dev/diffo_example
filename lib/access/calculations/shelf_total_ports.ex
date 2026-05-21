# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Calculations.ShelfTotalPorts do
  @moduledoc """
  Sums the `:ports` pool capacity across every card a shelf has assigned
  a slot to.

  For each outgoing slot-assignment (alias `:slot`, source = shelf), looks
  up the assigned card's `AssignableCharacteristic` for the `:ports` pool
  and sums `(last - first + 1)` across all of them.

  Local-to-this-repo for now. Could in time become a more general
  diffo-side primitive (`SumPoolCapacityOfAssignees` or similar) once the
  pattern repeats; the cleanest path may also be an ash_neo4j aggregate
  primitive that walks assignment edges natively. Worth its own yarn.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn shelf ->
      assignments =
        Diffo.Provider.AssignmentRelationship
        |> Ash.Query.filter_input(source_id: shelf.id, alias: :slot)
        |> Ash.read!(domain: Diffo.Provider)

      Enum.reduce(assignments, 0, fn assignment, acc ->
        case Diffo.Provider.AssignableCharacteristic
             |> Ash.Query.filter_input(instance_id: assignment.target_id, name: :ports)
             |> Ash.read_one!(domain: Diffo.Provider) do
          nil -> acc
          ports -> acc + (ports.last - ports.first + 1)
        end
      end)
    end)
  end
end

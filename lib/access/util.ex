# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Util do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Access - Access domain utility functions
  """

  require Ash.Query

  alias Diffo.Provider.Assignment

  def assignments(instance, type) do
    Enum.reduce(instance.reverse_relationships, [], fn reverse_relationship, acc ->
      IO.inspect(reverse_relationship, label: :reverse_relationship)

      case reverse_relationship.type do
        :assignedTo ->
          characteristic =
            Enum.find(reverse_relationship.characteristics, &(&1.name == type))

          case characteristic do
            nil ->
              acc

            _ ->
              [
                %Assignment{
                  id: Diffo.Unwrap.unwrap(characteristic.value),
                  assignable_type: type,
                  assignee_id: reverse_relationship.source_id
                }
                | acc
              ]
          end
      end
    end)
  end
end

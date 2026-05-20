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

  @doc """
  Lists things that are assigned_to an Instance, as Assignments
  """
  def assignments(instance, pool) when is_atom(pool) do
    instance.assignments
    |> Enum.filter(&(&1.pool == pool))
    |> Enum.map(fn a ->
      %Assignment{id: a.assigned, assignable_type: to_string(pool), assignee_id: a.source_id}
    end)
  end
end

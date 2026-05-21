# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Changes.Assign do
  @moduledoc """
  After-action for `:assign_*`-style update actions on Diffo Instance resources
  that declare pools.

  Applies the `:assignment` argument via `Assigner.assign/3` against the named
  pool, then reloads the instance through its primary read so preparations
  re-run.

  Pass the pool name as an option:

      update :assign_pair do
        argument :assignment, :struct, constraints: [instance_of: Assignment]
        change {DiffoExample.Changes.Assign, pool: :pairs}
      end
  """
  use Ash.Resource.Change
  require Ash.Query

  alias Diffo.Provider.Assigner

  @impl true
  def change(changeset, opts, _context) do
    pool = Keyword.fetch!(opts, :pool)

    Ash.Changeset.after_action(changeset, fn changeset, result ->
      mod = result.__struct__

      with {:ok, result} <- Assigner.assign(result, changeset, pool),
           {:ok, result} <-
             mod
             |> Ash.Query.for_read(:read)
             |> Ash.Query.filter(id == ^result.id)
             |> Ash.read_one() do
        {:ok, result}
      end
    end)
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Changes.Relate do
  @moduledoc """
  After-action for `:relate`-style update actions on Diffo Instance resources.

  Applies the `:relationships` argument via `Relationship.relate_instance`,
  then reloads the instance through its primary read so preparations re-run.

  Use it on any instance update action that carries
  `argument :relationships, {:array, :struct}`:

      update :relate do
        argument :relationships, {:array, :struct}
        change DiffoExample.Changes.Relate
      end
  """
  use Ash.Resource.Change
  require Ash.Query

  alias Diffo.Provider.Instance.Relationship

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, result ->
      mod = result.__struct__

      with {:ok, result} <- Relationship.relate_instance(result, changeset),
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

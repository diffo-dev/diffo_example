# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Changes.Define do
  @moduledoc """
  After-action for `:define`-style update actions on Diffo Instance resources.

  Applies the `:characteristic_value_updates` argument against the resource's
  compile-time `characteristics/0` and `pools/0` declarations, then reloads
  the instance through its primary read so preparations re-run.

  Use it on any instance update action that carries
  `argument :characteristic_value_updates, {:array, :term}`:

      update :define do
        argument :characteristic_value_updates, {:array, :term}

        change set_attribute(:resource_state, :operating)
        change DiffoExample.Changes.Define
      end

  Lifecycle transitions (resource_state for resources, transition_state for
  services) remain on the action — they are intent-specific.
  """
  use Ash.Resource.Change
  require Ash.Query

  alias Diffo.Provider.Extension.Characteristic
  alias Diffo.Provider.Extension.Pool

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, result ->
      mod = result.__struct__

      with {:ok, result} <- Ash.load(result, [:characteristics]),
           {:ok, result} <- Characteristic.update_all(result, changeset, mod.characteristics()),
           {:ok, result} <- Pool.update_pools(result, changeset, mod.pools()),
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

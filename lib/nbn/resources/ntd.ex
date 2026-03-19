# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Ntd do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Ntd - Network Termination Device Resource Instance

  An NTD is the device installed at the customer premises that connects
  the premises to the NBN network. It is related to a UNI resource.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.ActionHelper

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn

  resource do
    description "An Ash Resource representing a Network Termination Device (NTD)"
    plural_name :Ntds
  end

  specification do
    id "c3d4e5f6-7a8b-4c9d-ae0f-2a3b4c5d6e7f"
    name "ntd"
    type :resourceSpecification
    description "An NTD Resource Instance related to a UNI"
    category "Network Resource"
  end

  characteristics do
    characteristic :ntd, DiffoExample.Nbn.NtdValue
  end

  actions do
    create :build do
      description "creates a new NTD resource instance"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_ntd_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NTD"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_ntd_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the NTD with other instances (e.g. UNI)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_ntd_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

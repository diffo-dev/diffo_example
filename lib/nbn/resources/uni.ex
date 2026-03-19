# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Uni do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Uni - User Network Interface Resource Instance

  A UNI is the physical/logical interface at the customer premises. It is
  related to an NTD resource and to its parent NBN Ethernet circuit.
  It is related to an AVC resource, which is in turn aggregated by a CVC.
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
    description "An Ash Resource representing a User Network Interface (UNI)"
    plural_name :Unis
  end

  specification do
    id "a1b2c3d4-5e6f-4a7b-8c9d-0e1f2a3b4c5d"
    name "uni"
    type :resourceSpecification
    description "A UNI Resource Instance related to an NTD and an NBN Ethernet circuit"
    category "Network Resource"
  end

  characteristics do
    characteristic :uni, DiffoExample.Nbn.UniValue
  end

  actions do
    create :build do
      description "creates a new UNI resource instance"
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
               ActionHelper.build_after(changeset, result, Nbn, :get_uni_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the UNI"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_uni_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the UNI with other instances (e.g. NTD, NBN Ethernet circuit)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_uni_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

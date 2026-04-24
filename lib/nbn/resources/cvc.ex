# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Cvc do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Cvc - Connectivity Virtual Circuit Resource Instance

  A CVC is the wholesale bandwidth product that supports AVC and terminates at an NNI Group.
  The CVC assigns cvlan to AVC.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.ActionHelper
  alias Diffo.Provider.Assigner
  alias Diffo.Provider.Assignment

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "cvc"
  end

  resource do
    description "An Ash Resource representing a Connectivity Virtual Circuit (CVC)"
    plural_name :Cvcs
  end

  specification do
    id "d4e5f6a7-8b9c-4d0e-bf1a-3b4c5d6e7f8a"
    name "cvc"
    type :resourceSpecification

    description "A Connectivity Virtual Circuit Resource Instance that aggregates AVCs and terminates at an NNI Group"

    category "Network Resource"
  end

  characteristics do
    characteristic :cvc, DiffoExample.Nbn.CvcValue
    characteristic :cvlans, Diffo.Provider.AssignableValue
  end

  actions do
    create :build do
      description "creates a new CVC resource instance"
      accept [:id, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:name, &DiffoExample.Nbn.Cvc.identifier/0)

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_cvc_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the CVC"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_cvc_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :assign_cvlan do
      description "assigns a C-VLAN ID from the CVC pool to an AVC"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Assigner.assign(result, changeset, :cvlans, :cvlan),
                    {:ok, result} <- Nbn.get_cvc_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the CVC with other instances (e.g. AVC aggregation, NNI Group termination)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_cvc_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :mine do
      description "updates the CVC with data mined from related instances"
      argument :characteristic_value_updates, {:array, :term}

      change before_action(fn changeset, context ->
               DiffoExample.Nbn.Cvc.mine_related(changeset, context)
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_cvc_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("CVC")
  end

  # mines related resource to characteristics
  def mine_related(changeset, _context) when is_struct(changeset, Ash.Changeset) do
    reverse_relationships = Ash.Changeset.get_attribute(changeset, :reverse_relationships)

    svlan = {:svlan, Diffo.Unwrap.unwrap(hd(hd(reverse_relationships).characteristics).value)}

    Ash.Changeset.force_set_argument(changeset, :characteristic_value_updates, cvc: [svlan])
  end
end

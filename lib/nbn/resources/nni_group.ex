# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NniGroup do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NniGroup - NNI Group Resource Instance

  An NNI Group is the Point of Interconnect (PoI) grouping where a CVC
  terminates. It comprises multiple NNI resources.
  The NNI Group assigns svlan to CVC.
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
    domain: Nbn

  resource do
    description "An Ash Resource representing an NNI Group"
    plural_name :NniGroups
  end

  specification do
    id "e5f6a7b8-9c0d-4e1f-8a2b-4c5d6e7f8a9b"
    name "nniGroup"
    type :resourceSpecification
    description "An NNI Group Resource Instance comprising multiple NNI resources"
    category "Network Resource"
  end

  characteristics do
    characteristic :nni_group, DiffoExample.Nbn.NniGroupValue
    characteristic :svlans, Diffo.Provider.AssignableValue
  end

  actions do
    create :build do
      description "creates a new NNI Group resource instance"
      accept [:id, :name, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context -> ActionHelper.build_before(changeset) end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result, Nbn, :get_nni_group_by_id)
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NNI Group"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Nbn.get_nni_group_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :assign_svlan do
      description "assigns an S-VLAN ID from the NNI Group pool to a CVC"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Assigner.assign(result, changeset, :svlans, :svlan),
                    {:ok, result} <- Nbn.get_nni_group_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the NNI Group with other instances (e.g. NNI resources it comprises)"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_nni_group_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

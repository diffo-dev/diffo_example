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
  alias Diffo.Provider.Extension.Characteristic
  alias Diffo.Provider.Assigner
  alias Diffo.Provider.Assignment
  alias Diffo.Provider.Extension.Pool

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn,
    extensions: [AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  resource do
    description "An Ash Resource representing a Connectivity Virtual Circuit (CVC)"
    plural_name :Cvcs
  end

  json_api do
    type "cvc"
  end

  provider do
    specification do
      id "d4e5f6a7-8b9c-4d0e-bf1a-3b4c5d6e7f8a"
      name "cvc"
      type :resourceSpecification

      description "A Connectivity Virtual Circuit Resource Instance that aggregates AVCs and terminates at an NNI Group"

      category "Network Resource"
    end

    characteristics do
      characteristic :cvc, DiffoExample.Nbn.CvcCharacteristic
    end

    pools do
      pool :cvlans, :cvlan
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      description "creates a new CVC resource instance"
      accept [:id, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:name, &DiffoExample.Nbn.Cvc.identifier/0)
      change set_attribute(:type, :resource)
      change DiffoExample.Nbn.Changes.SetRspId
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the CVC"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_all(result, changeset, characteristics()),
                    {:ok, result} <- Pool.update_pools(result, changeset, pools()),
                    {:ok, result} <- Nbn.get_cvc_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :assign_cvlan do
      description "assigns a C-VLAN ID from the CVC pool to an AVC"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Assigner.assign(result, changeset, :cvlans),
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
  end

  attributes do
    attribute :rsp_id, :string do
      description "the owning RSP's id — nil for Perentie-managed infrastructure"
      allow_nil? true
      public? true
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("CVC")
  end

  use DiffoExample.Nbn.RspOwnership
end

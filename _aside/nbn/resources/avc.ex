# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Avc do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Avc - Access Virtual Circuit Resource Instance

  An AVC is the virtual circuit dedicated to an NBN Ethernet circuit,
  carrying traffic between its related UNI and the CVC that aggregates it.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Extension.Characteristic

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn,
    extensions: [AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  resource do
    description "An Ash Resource representing an Access Virtual Circuit (AVC)"
    plural_name :Avcs
  end

  json_api do
    type "avc"
  end

  provider do
    specification do
      id "b2c3d4e5-6f7a-4b8c-9d0e-1f2a3b4c5d6e"
      name "avc"
      type :resourceSpecification
      description "An AVC Resource Instance dedicated to an NBN Ethernet circuit"
      category "Network Resource"
    end

    characteristics do
      characteristic :avc, DiffoExample.Nbn.AvcCharacteristic
      characteristic :cvc, DiffoExample.Nbn.CvcCharacteristic
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      description "creates a new AVC resource instance"
      accept [:id, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:name, &DiffoExample.Nbn.Avc.identifier/0)
      change set_attribute(:type, :resource)
      change DiffoExample.Nbn.Changes.SetRspId
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the AVC"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_all(result, changeset, characteristics()),
                    {:ok, result} <- Nbn.get_avc_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the AVC with other instances"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Nbn.get_avc_by_id(result.id),
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
    DiffoExample.Nbn.Util.identifier("AVC")
  end

  use DiffoExample.Nbn.RspOwnership
end

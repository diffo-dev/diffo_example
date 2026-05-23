# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NbnEthernet do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NbnEthernet - NBN Ethernet access Resource Instance

  An NBN Ethernet access comprises of dedicated UNI and AVC resources.
  """

  alias Diffo.Provider.BaseInstance

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Nbn,
    extensions: [AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  resource do
    description "An Ash Resource representing an NBN Ethernet access"
    plural_name :NbnEthernets
  end

  json_api do
    type "nbnEthernet"
  end

  provider do
    specification do
      id "f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c"
      name "nbnEthernet"
      type :resourceSpecification
      description "An NBN Ethernet access comprising a dedicated UNI and AVC"
      category "Network Resource"
    end

    characteristics do
      characteristic :pri, DiffoExample.Nbn.PriCharacteristic
    end

    relationships do
      source :all
      target :all
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      description "creates a new NBN Ethernet access resource instance"
      accept [:id, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:name, &DiffoExample.Nbn.NbnEthernet.identifier/0)
      change set_attribute(:type, :resource)
      change DiffoExample.Nbn.Changes.SetRspId
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NBN Ethernet access"
      argument :characteristic_value_updates, {:array, :term}

      change set_attribute(:resource_state, :operating)
      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the NBN Ethernet access with other instances (e.g. UNI)"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end
  end

  attributes do
    attribute :rsp_id, :string do
      description "the owning RSP's id — nil for Perentie-managed infrastructure"
      allow_nil? true
      public? true
    end
  end

  calculations do
    # The singular AVC this access owns — single-hop via :avc owns relationship.
    calculate :avc,
              :map,
              {DiffoExample.Calculations.InheritedCharacteristicViaRelationship,
               [
                 alias: :avc,
                 characteristic_module: DiffoExample.Nbn.AvcCharacteristic,
                 singular?: true
               ]} do
      public? true
    end

    # The singular UNI this access owns — single-hop via :uni owns relationship.
    calculate :uni,
              :map,
              {DiffoExample.Calculations.InheritedCharacteristicViaRelationship,
               [
                 alias: :uni,
                 characteristic_module: DiffoExample.Nbn.UniCharacteristic,
                 singular?: true
               ]} do
      public? true
    end

    # The singular CVC backing this access's AVC — two-hop via :avc owns
    # relationship, then back via the AVC's incoming :cvlan assignment.
    calculate :cvc,
              :map,
              {DiffoExample.Calculations.InheritedCharacteristicViaRelationship,
               [
                 alias: :avc,
                 then_via: [:cvlan],
                 characteristic_module: DiffoExample.Nbn.CvcCharacteristic,
                 singular?: true
               ]} do
      public? true
    end

    # The singular NTD this access's UNI plugs into — two-hop via :uni
    # owns relationship, then back via the UNI's incoming :port assignment.
    calculate :ntd,
              :map,
              {DiffoExample.Calculations.InheritedCharacteristicViaRelationship,
               [
                 alias: :uni,
                 then_via: [:port],
                 characteristic_module: DiffoExample.Nbn.NtdCharacteristic,
                 singular?: true
               ]} do
      public? true
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("PRI")
  end

  use DiffoExample.Nbn.RspOwnership
end

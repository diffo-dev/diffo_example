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

      change set_attribute(:resource_state, :operating)
      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the AVC with other instances"
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
    # The CVC characteristic value brought up from the singular CVC this
    # AVC is part of — single-hop via the AVC's :cvc consumer-alias on its
    # cvlan assignment from the CVC.
    calculate :cvc,
              :map,
              {DiffoExample.Calculations.InheritedCharacteristicViaAssignment,
               [
                 via: [:cvc],
                 characteristic_module: DiffoExample.Nbn.CvcCharacteristic,
                 singular?: true
               ]} do
      public? true
    end

    # The singular NniGroup characteristic value brought up transitively —
    # AVC's :cvc alias to the CVC, then the CVC's :nni_group alias to its
    # NniGroup. Two-hop via [:cvc, :nni_group].
    calculate :nni_group,
              :map,
              {DiffoExample.Calculations.InheritedCharacteristicViaAssignment,
               [
                 via: [:cvc, :nni_group],
                 characteristic_module: DiffoExample.Nbn.NniGroupCharacteristic,
                 singular?: true
               ]} do
      public? true
    end
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("AVC")
  end

  use DiffoExample.Nbn.RspOwnership
end

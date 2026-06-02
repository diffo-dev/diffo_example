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
  alias Diffo.Provider.Resource
  alias Diffo.Provider.Assignment

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance, Resource],
    domain: Nbn,
    authorizers: [Ash.Policy.Authorizer]

  resource do
    description "An Ash Resource representing a Connectivity Virtual Circuit (CVC)"
    plural_name :Cvcs
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
      characteristic :metrics, DiffoExample.Nbn.CvcMetrics

      # The NNI Group this CVC is assigned an svlan from — single-hop via the
      # CVC's :nni_group consumer-alias. Structurally one, so collapse.
      inherited_characteristic :nni_group, collapse: :first
    end

    pools do
      pool :cvlans, :cvlan
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

      change set_attribute(:lifecycle_state, :installed)
      change Diffo.Provider.Changes.Define
    end

    update :assign_cvlan do
      description "assigns a C-VLAN ID from the CVC pool to an AVC"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change {Diffo.Provider.Changes.Assign, pool: :cvlans}
    end

    update :relate do
      description "relates the CVC with other instances (e.g. AVC aggregation, NNI Group termination)"
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
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("CVC")
  end

  use DiffoExample.Nbn.RspOwnership
end

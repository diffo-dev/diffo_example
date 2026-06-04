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
  alias Diffo.Provider.Resource

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance, Resource],
    domain: Nbn,
    authorizers: [Ash.Policy.Authorizer]

  resource do
    description "An Ash Resource representing an NBN Ethernet access"
    plural_name :NbnEthernets
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

      # PRI owns its AVC (:circuit) and UNI (:port) via forward :owns
      # relationships (PRI is the edge source → forward_relationships), each
      # singular. The CVC and NTD are two-hop mixed chains: forward :owns to
      # the AVC/UNI, then reverse the assignment that resource holds (:cvc /
      # :ntd) back to its assigner.
      inherited_characteristic :avc,
        via: [{:forward, relationship: [alias: :circuit]}],
        read: :avc,
        collapse: :first

      inherited_characteristic :uni,
        via: [{:forward, relationship: [alias: :port]}],
        read: :uni,
        collapse: :first

      inherited_characteristic :cvc,
        via: [{:forward, relationship: [alias: :circuit]}, {:reverse, assignment: :cvc}],
        read: :cvc,
        collapse: :first

      inherited_characteristic :ntd,
        via: [{:forward, relationship: [alias: :port]}, {:reverse, assignment: :ntd}],
        read: :ntd,
        collapse: :first
    end

    places do
      # The PRI surfaces the geography of the service it realises (#65). inherited_place
      # reaches an instance via the bearer chain, then reads one of its place refs
      # (source_role); it can't hop place→place (diffo #227), so the NNI Group carries
      # both POI and CSA, and the NTD both LocationPoint and Location — read here.
      #
      # Network edge — reach the NNI Group (PRI → AVC → CVC → NNI Group):
      inherited_place :poi,
        via: [
          {:forward, relationship: [alias: :circuit]},
          {:reverse, assignment: :cvc},
          {:reverse, assignment: :nni_group}
        ],
        source_role: :locates,
        collapse: :first

      inherited_place :csa,
        via: [
          {:forward, relationship: [alias: :circuit]},
          {:reverse, assignment: :cvc},
          {:reverse, assignment: :nni_group}
        ],
        source_role: :serves,
        collapse: :first

      # Customer premises — reach the NTD (PRI → UNI → NTD):
      inherited_place :location_point,
        via: [{:forward, relationship: [alias: :port]}, {:reverse, assignment: :ntd}],
        source_role: :locates,
        collapse: :first

      inherited_place :location,
        via: [{:forward, relationship: [alias: :port]}, {:reverse, assignment: :ntd}],
        source_role: :addressed_at,
        collapse: :first
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

      change set_attribute(:lifecycle_state, :installed)
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
  end

  def identifier() do
    DiffoExample.Nbn.Util.identifier("PRI")
  end

  use DiffoExample.Nbn.RspOwnership
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Rsp do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Rsp - Retail Service Provider

  An RSP is a licensed provider operating within the Perentie ecosystem.
  Each RSP is assigned an EPID (four-digit regulator-assigned identifier)
  and a short_name atom used as their actor identity for authorisation.

  RSP is a Party of kind :organization. The EPID is used as the Party id (Neo4j key).
  """

  alias DiffoExample.Nbn

  use Ash.Resource,
    domain: Nbn,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshStateMachine, AshJsonApi.Resource],
    fragments: [Diffo.Provider.BaseParty]

  # BaseParty provides:
  #   data_layer: AshNeo4j.DataLayer
  #   extensions: AshJason.Resource, AshOutstanding.Resource, Diffo.Provider.Party.Extension
  #   Neo4j label :Party (RSP nodes are Party nodes)
  #   attributes: id (string/key), name, type, referred_type, created_at, updated_at
  #   relationships: party_refs
  #   actions: :read (primary), :destroy, :create (accept [:id,:name,:type,:referred_type]),
  #            :update (name), :list (unsorted), :find_by_name

  json_api do
    type "rsp"
  end

  state_machine do
    initial_states [:inactive]
    default_initial_state :inactive
    state_attribute :state

    transitions do
      transition action: :activate, from: [:inactive, :suspended], to: :active
      transition action: :suspend, from: :active, to: :suspended
      transition action: :deactivate, from: [:active, :suspended], to: :inactive
    end
  end

  attributes do
    attribute :short_name, :atom do
      description "atom identifier used as the actor for authorisation"
      allow_nil? false
      public? true
    end

    attribute :state, :atom do
      allow_nil? false
      default :inactive
      public? true
      constraints [one_of: [:active, :suspended, :inactive]]
    end
  end

  instances do
    role :owner, DiffoExample.Nbn.Avc
    # pending resolution of /diffo-dev/diffo#101
    #role :owner, DiffoExample.Nbn.Cvc
    #role :owner, DiffoExample.Nbn.Nni
    #role :owner, DiffoExample.Nbn.NniGroup
    #role :owner, DiffoExample.Nbn.NbnEthernet
  end

  actions do
    create :build do
      accept [:name, :short_name, :id]
      upsert? true
      change set_attribute(:type, :Organization)
      validate match(:id, ~r/^\d{4}$/) do
        message "must be a four-digit EPID"
      end
    end

    read :inventory do
      prepare build(sort: [id: :asc])
    end

    update :activate do
      require_atomic? false
      change transition_state(:active)
    end

    update :suspend do
      require_atomic? false
      change transition_state(:suspended)
    end

    update :deactivate do
      require_atomic? false
      change transition_state(:inactive)
    end
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_short_name, [:short_name]
  end

  policies do
    bypass DiffoExample.Nbn.Checks.NoActor do
      authorize_if always()
    end

    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end

  field_policies do
    field_policy :state do
      authorize_if DiffoExample.Nbn.Checks.NoActor
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if expr(^actor(:id) == id)
    end

    field_policy :* do
      authorize_if always()
    end
  end
end

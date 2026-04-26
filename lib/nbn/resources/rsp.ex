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
  """

  alias DiffoExample.Nbn

  use Ash.Resource,
    domain: Nbn,
    data_layer: AshNeo4j.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshStateMachine, AshJason.Resource, AshJsonApi.Resource]

  neo4j do
    label :Rsp
  end

  json_api do
    type "rsp"
  end

  jason do
    pick [:id, :name, :short_name, :epid, :state]
    compact true
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
    attribute :id, :uuid do
      primary_key? true
      allow_nil? false
      public? true
      default &Ash.UUID.generate/0
      source :uuid
    end

    attribute :name, :string do
      description "the RSP's registered trading name"
      allow_nil? false
      public? true
    end

    attribute :short_name, :atom do
      description "atom identifier used as the actor for authorisation"
      allow_nil? false
      public? true
    end

    attribute :epid, :string do
      description "four-digit regulator-assigned provider identifier, in historical sequence"
      allow_nil? false
      public? true
      constraints [match: ~r/^\d{4}$/]
    end

    attribute :state, :atom do
      allow_nil? false
      default :inactive
      public? true
      constraints [one_of: [:active, :suspended, :inactive]]
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true
    end

    read :list do
      prepare build(sort: [epid: :asc])
    end

    create :create do
      accept [:name, :short_name, :epid]
      upsert? true
      upsert_identity :unique_epid
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
    identity :unique_epid, [:epid]
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

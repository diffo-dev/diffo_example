# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Ntd do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Ntd - Network Termination Device Resource Instance

  An NTD is the device installed at the customer premises that connects
  the premises to the NBN network. The NTD can assign ports to UNI.
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Resource
  alias Diffo.Provider.Assignment

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance, Resource],
    domain: Nbn,
    authorizers: [Ash.Policy.Authorizer]

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

  resource do
    description "An Ash Resource representing a Network Termination Device (NTD)"
    plural_name :Ntds
  end

  provider do
    specification do
      id "c3d4e5f6-7a8b-4c9d-ae0f-2a3b4c5d6e7f"
      name "ntd"
      type :resourceSpecification
      description "An NTD Resource Instance related to a UNI"
      category "Network Resource"
    end

    characteristics do
      characteristic :ntd, DiffoExample.Nbn.NtdCharacteristic
    end

    pools do
      pool :ports, :port
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

  def identifier() do
    DiffoExample.Nbn.Util.identifier("NTD")
  end

  actions do
    create :build do
      description "creates a new NTD resource instance"
      accept [:id, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change set_attribute(:name, &DiffoExample.Nbn.Ntd.identifier/0)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the NTD"
      argument :characteristic_value_updates, {:array, :term}

      change set_attribute(:lifecycle_state, :installed)
      change Diffo.Provider.Changes.Define
    end

    update :assign_port do
      description "assigns a port from the NTD pool to a UNI"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change {Diffo.Provider.Changes.Assign, pool: :ports}
    end

    update :relate do
      description "relates the NTD with other instances (e.g. UNI)"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end
  end

  calculations do
    # The UNI characteristic value of every UNI this NTD has assigned a
    # port to — reverse traversal of outgoing :port AssignmentRelationships
    # sourced from this NTD. Low cardinality (typical NTD has a handful of
    # ports). Filter by `thing` (the pool's thing name) rather than `alias`
    # — see assignment-direction-asymmetry memory.
    calculate :unis,
              {:array, :map},
              {DiffoExample.Calculations.ReverseInheritedCharacteristic,
               [thing: :port, characteristic_module: DiffoExample.Nbn.UniCharacteristic]} do
      public? true
    end
  end
end

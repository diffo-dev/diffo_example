# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Uni do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Uni - User Network Interface Resource Instance

  A UNI is the physical/logical interface at the customer premises. It is
  related to an NTD resource and to its parent NBN Ethernet access.
  It is related to an AVC resource, which is in turn aggregated by a CVC.
  """

  alias Diffo.Provider.BaseInstance

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BaseInstance],
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
    description "An Ash Resource representing a User Network Interface (UNI)"
    plural_name :Unis
  end

  provider do
    specification do
      id "a1b2c3d4-5e6f-4a7b-8c9d-0e1f2a3b4c5d"
      name "uni"
      type :resourceSpecification
      description "A UNI Resource Instance related to an NTD and an NBN Ethernet access"
      category "Network Resource"
    end

    characteristics do
      characteristic :uni, DiffoExample.Nbn.UniCharacteristic
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
    DiffoExample.Nbn.Util.identifier("UNI")
  end

  actions do
    create :build do
      description "creates a new UNI resource instance"
      accept [:id, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change set_attribute(:name, &DiffoExample.Nbn.Uni.identifier/0)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the UNI"
      argument :characteristic_value_updates, {:array, :term}

      change set_attribute(:resource_state, :operating)
      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the UNI with other instances (e.g. NTD, NBN Ethernet access)"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end
  end
end

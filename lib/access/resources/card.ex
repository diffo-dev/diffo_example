# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Card do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Card - Card Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Resource
  alias Diffo.Provider.Assignment

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance, Resource],
    domain: Access

  resource do
    description "An Ash Resource representing a Card"
    plural_name :Cards
  end

  provider do
    specification do
      id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
      name "card"
      type :resourceSpecification
      description "A Card Resource Instance"
      category "Network Resource"
    end

    characteristics do
      characteristic :card, DiffoExample.Access.CardCharacteristic
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

  actions do
    create :build do
      description "creates a new Card resource instance for build"
      accept [:id, :name, :type, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the card"
      argument :characteristic_value_updates, {:array, :term}

      change set_attribute(:lifecycle_state, :installed)
      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the card with other instances"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end

    update :assign_port do
      description "relates the card with an instance by assigning a port"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change {Diffo.Provider.Changes.Assign, pool: :ports}
    end
  end

  calculations do
    # The shelf characteristic value brought up from the shelf this card
    # is part of — Card's :shelf consumer-alias on its slot assignment
    # from the Shelf.
    calculate :shelf,
              {:array, :map},
              {DiffoExample.Calculations.InheritedCharacteristicViaAssignment,
               [via: [:shelf], characteristic_module: DiffoExample.Access.ShelfCharacteristic]} do
      public? true
    end

    # The slot number this card occupies on its shelf — the :value of
    # the assignment Card aliases :shelf (its upstream Shelf).
    calculate :slot,
              {:array, :integer},
              {Diffo.Provider.Calculations.FieldFromAssignment, [alias: :shelf, field: :value]} do
      public? true
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Shelf do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Shelf - Shelf Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Resource
  alias Diffo.Provider.Assignment

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance, Resource],
    domain: Access

  resource do
    description "An Ash Resource representing a Shelf"
    plural_name :Shelves
  end

  provider do
    specification do
      id "ef016d85-9dbd-429c-84da-1df56cc7dda5"
      name "shelf"
      type :resourceSpecification
      description "A Shelf Resource Instance which contain cards"
      category "Network Resource"
    end

    characteristics do
      characteristic :shelf, DiffoExample.Access.ShelfCharacteristic
    end

    pools do
      pool :slots, :slot
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
      description "creates a new Shelf resource instance for build"
      accept [:id, :name, :type, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the shelf"
      argument :characteristic_value_updates, {:array, :term}

      change set_attribute(:lifecycle_state, :installed)
      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the shelf with cards"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end

    update :assign_slot do
      description "relates the shelf with an instance by assigning a slot"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change {Diffo.Provider.Changes.Assign, pool: :slots}
    end
  end

  calculations do
    # Brings up the card characteristic of every card this shelf has
    # assigned a slot to, ordered by slot number. Cards-as-assignees name
    # their slot :slot when requesting; the calc filters outgoing
    # AssignmentRelationship records by that alias.
    calculate :cards,
              {:array, :map},
              {DiffoExample.Calculations.ReverseInheritedCharacteristic,
               [alias: :shelf, characteristic_module: DiffoExample.Access.CardCharacteristic]} do
      public? true
    end

    # Sum of port capacity across every card assigned to this shelf.
    # Each card's :ports pool size is `(last - first + 1)`. Reaches across
    # the slot-assignment chain to AssignableCharacteristic on each card.
    calculate :total_ports,
              :integer,
              DiffoExample.Access.Calculations.ShelfTotalPorts do
      public? true
    end
  end
end

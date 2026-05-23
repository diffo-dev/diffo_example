# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Path do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Path - Path Resource Instance
  """

  alias Diffo.Provider.BaseInstance

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Path"
    plural_name :Paths
  end

  provider do
    specification do
      id "1d507914-8f76-48cb-aa0e-3a8f92951ab0"
      name "path"
      type :resourceSpecification
      description "A Path Resource Instance"
      category "Network Resource"
    end

    characteristics do
      characteristic :path, DiffoExample.Access.PathCharacteristic
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
      description "creates a new Path resource instance for build"
      accept [:id, :name, :type, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the path"
      argument :characteristic_value_updates, {:array, :term}

      change Diffo.Provider.Changes.Define
    end

    update :relate do
      description "relates the path with other instances"
      argument :relationships, {:array, :struct}

      change Diffo.Provider.Changes.Relate
    end
  end

  calculations do
    # The card characteristic value brought up from the card this path is
    # part of — Path's :card consumer-alias on its port assignment from
    # the Card.
    calculate :card,
              {:array, :map},
              {DiffoExample.Calculations.InheritedCharacteristicViaAssignment,
               [via: [:card], characteristic_module: DiffoExample.Access.CardCharacteristic]} do
      public? true
    end

    # The port number this path occupies on its card — the :value of the
    # assignment Path aliases :card (its upstream Card).
    calculate :port,
              {:array, :integer},
              {Diffo.Provider.Calculations.FieldFromAssignment, [alias: :card, field: :value]} do
      public? true
    end

    # The shelf characteristic value brought up transitively — Path's
    # :card alias to the Card, then the Card's :shelf alias to its Shelf.
    # Two-hop via [:card, :shelf].
    calculate :shelf,
              {:array, :map},
              {DiffoExample.Calculations.InheritedCharacteristicViaAssignment,
               [
                 via: [:card, :shelf],
                 characteristic_module: DiffoExample.Access.ShelfCharacteristic
               ]} do
      public? true
    end
  end
end

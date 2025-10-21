# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Card do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Card - Card Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Assigner
  alias Diffo.Provider.Assignment

  alias DiffoExample.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Card"
    plural_name :Cards
  end

  specification do
    id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
    name "card"
    type :resourceSpecification
    description "A Card Resource Instance"
    category "Network Resource"
  end

  characteristics do
    characteristic :card, DiffoExample.Access.CardValue
    characteristic :ports, Diffo.Provider.AssignableValue
  end

  actions do
    create :build do
      description "creates a new Card resource instance for build"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context ->
               changeset
               |> Specification.set_specified_by_argument()
               |> Feature.set_features_argument()
               |> Characteristic.set_characteristics_argument()
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Specification.relate_instance(result, changeset),
                    {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Feature.relate_instance(result, changeset),
                    {:ok, result} <- Characteristic.relate_instance(result, changeset),
                    {:ok, result} <- Place.relate_instance(result, changeset),
                    {:ok, result} <- Party.relate_instance(result, changeset),
                    {:ok, result} <- Access.get_card_by_id(result.id),
                    do: {:ok, result}
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the card"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Characteristic.update_values(result, changeset),
                    {:ok, result} <- Access.get_card_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the card with other instances"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Access.get_card_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :assign_port do
      description "relates the card with an instance by assigning a port"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Assigner.assign(result, changeset, :ports, :port),
                    {:ok, result} <- Access.get_card_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end

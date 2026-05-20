# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.CardTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Assignment
  alias DiffoExample.Access
  alias DiffoExample.Access.Card
  alias DiffoExample.Test.Characteristics
  alias DiffoExample.Util

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build card" do
    test "create a card" do
      {:ok, card} = Access.build_card(%{})

      assert is_struct(card, Card)

      refute is_nil(card.specification_id)
      assert is_struct(card.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: card.id},
               :Specification,
               %{uuid: card.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # typed characteristics are not in instance.characteristics
      assert is_list(card.characteristics)
      assert length(card.characteristics) == 0

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates() |> Util.summarise_characteristics(card)

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"}}) |> Util.summarise_characteristics(card)
    end

    test "define card" do
      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [
          card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
          ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
        ],
        card
      )

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates() |> Util.summarise_characteristics(card)

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\"}) |> Util.summarise_characteristics(card)
    end

    test "auto assign port to service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([ports: [free: 47]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates() |> Util.summarise_characteristics(card)

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]}]}) |> Util.summarise_characteristics(card)
    end

    test "auto assign two ports to same service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([ports: [free: 46]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates() |> Util.summarise_characteristics(card)

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]},{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":2}]}]}) |> Util.summarise_characteristics(card)
    end

    test "specific assignment rejects duplicate request" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      {:error, _error} =
        Access.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      Characteristics.check_values([ports: [free: 47]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates() |> Util.summarise_characteristics(card)

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":5}]}]}) |> Util.summarise_characteristics(card)
    end
  end
end

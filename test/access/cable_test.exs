# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.CableTest do
  @moduledoc false
  use DiffoExample.DataCase, async: true

  alias Diffo.Provider.Specification
  alias Diffo.Provider.Assignment
  alias DiffoExample.Access
  alias DiffoExample.Access.Cable
  alias DiffoExample.Access.IntegerUnit
  alias DiffoExample.Test.Characteristics

  describe "build cable" do
    test "create a cable" do
      {:ok, cable} = Access.build_cable(%{})

      assert is_struct(cable, Cable)

      refute is_nil(cable.specification_id)
      assert is_struct(cable.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: cable.id},
               :Specification,
               %{uuid: cable.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # typed characteristics are not in instance.characteristics
      assert is_list(cable.characteristics)
      assert length(cable.characteristics) == 0

      encoding =
        Jason.encode!(cable)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{cable.id}",\"category\":\"Network Resource\",\"description\":\"A Cable Resource Instance\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":1,\"algorithm\":\"lowest\"}}]})
    end

    test "define cable" do
      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, assignable_type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [
          cable: [pairs: 60, technology: :PIUT],
          pairs: [first: 1, last: 60, assignable_type: "copper"]
        ],
        cable
      )

      encoding =
        Jason.encode!(cable)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{cable.id}",\"category\":\"Network Resource\",\"description\":\"A Cable Resource Instance\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"installed\",\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign pair to service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, assignable_type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([pairs: [free: 59]], cable)

      encoding =
        Jason.encode!(cable)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{cable.id}",\"category\":\"Network Resource\",\"description\":\"A Cable Resource Instance\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"installed\",\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":1}]}],\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign two pairs to same service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, assignable_type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([pairs: [free: 58]], cable)

      encoding =
        Jason.encode!(cable)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{cable.id}",\"category\":\"Network Resource\",\"description\":\"A Cable Resource Instance\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"installed\",\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":1}]},{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":2}]}],\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end

    test "specific assignment rejects duplicate request" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, assignable_type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      {:error, _error} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      Characteristics.check_values([pairs: [free: 59]], cable)

      encoding =
        Jason.encode!(cable)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{cable.id}",\"category\":\"Network Resource\",\"description\":\"A Cable Resource Instance\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"installed\",\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":5}]}],\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end
  end
end

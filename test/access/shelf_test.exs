# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.ShelfTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Diffo.Provider
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Assignment
  alias DiffoExample.Access
  alias DiffoExample.Access.Shelf
  alias DiffoExample.Test.Characteristics
  alias DiffoExample.Test.Parties
  alias DiffoExample.Test.Places
  alias DiffoExample.Util

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build shelf" do
    test "create a shelf" do
      places = [create_esa_place()]
      parties = [create_provider_party()]

      {:ok, shelf} = Access.build_shelf(%{name: "QDONC-0001", places: places, parties: parties})

      # check the instance is a Shelf
      assert is_struct(shelf, Shelf)

      # check specification resource enrichment and node relationship
      refute is_nil(shelf.specification_id)
      assert is_struct(shelf.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: shelf.id},
               :Specification,
               %{uuid: shelf.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # typed characteristics are not in instance.characteristics
      assert is_list(shelf.characteristics)
      assert length(shelf.characteristics) == 0

      Places.check_places(places, shelf)
      Parties.check_parties(parties, shelf)

      encoding =
        Jason.encode!(shelf)
        |> Diffo.Util.summarise_dates()
        |> Util.summarise_characteristics(shelf)

      assert encoding ==
               ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{shelf.id}",\"category\":\"Network Resource\",\"description\":\"A Shelf Resource Instance which contain cards\",\"name\":\"QDONC-0001\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{}},{\"name\":\"slots\",\"value\":{\"first\":1,\"last\":1,\"free\":1,\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
               |> Util.summarise_characteristics(shelf)
    end
  end

  test "define shelf" do
    places = [create_esa_place()]
    parties = [create_provider_party()]
    {:ok, shelf} = Access.build_shelf(%{name: "QDONC-0001", places: places, parties: parties})

    updates = [
      shelf: [device_name: "QDONC-1001", family: :ISAM, model: "ISAM7330", technology: :DSLAM],
      slots: [first: 1, last: 10, assignable_type: "LineCard"]
    ]

    {:ok, shelf} = Access.define_shelf(shelf, %{characteristic_value_updates: updates})

    encoding =
      Jason.encode!(shelf)
      |> Diffo.Util.summarise_dates()
      |> Util.summarise_characteristics(shelf)

    assert encoding ==
             ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{shelf.id}",\"category\":\"Network Resource\",\"description\":\"A Shelf Resource Instance which contain cards\",\"name\":\"QDONC-0001\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{\"name\":\"QDONC-1001\",\"family\":\"ISAM\",\"model\":\"ISAM7330\",\"technology\":\"DSLAM\"}},{\"name\":\"slots\",\"value\":{\"first\":1,\"last\":10,\"free\":10,\"type\":\"LineCard\",\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
             |> Util.summarise_characteristics(shelf)
  end

  test "relate common cards" do
    places = [create_esa_place()]
    parties = [create_provider_party()]

    {:ok, shelf} = Access.build_shelf(%{places: places, parties: parties})

    updates = [
      shelf: [device_name: "QDONC-1001", family: :ISAM, model: "ISAM7330", technology: :DSLAM],
      slots: [first: 1, last: 10, assignable_type: "LineCard"]
    ]

    {:ok, shelf} = Access.define_shelf(shelf, %{characteristic_value_updates: updates})

    cards = create_common_cards()

    {:ok, shelf} = Access.relate_shelf(shelf, %{relationships: cards})

    encoding =
      Jason.encode!(shelf)
      |> Diffo.Util.summarise_dates()
      |> Util.summarise_characteristics(shelf)

    [card0, card1, card2, card3] = cards

    # resource relationships are sorted in the create order of the relationships
    assert encoding ==
             ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{shelf.id}",\"category\":\"Network Resource\",\"description\":\"A Shelf Resource Instance which contain cards\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"resourceRelationship\":[{\"type\":\"contains\",\"resource\":{\"id\":\"#{card0.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{card0.id}\"}},{\"type\":\"contains\",\"resource\":{\"id\":\"#{card1.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{card1.id}\"}},{\"type\":\"contains\",\"resource\":{\"id\":\"#{card2.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{card2.id}\"}},{\"type\":\"contains\",\"resource\":{\"id\":\"#{card3.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{card3.id}\"}}],\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{\"name\":\"QDONC-1001\",\"family\":\"ISAM\",\"model\":\"ISAM7330\",\"technology\":\"DSLAM\"}},{\"name\":\"slots\",\"value\":{\"first\":1,\"last\":10,\"free\":10,\"type\":\"LineCard\",\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
             |> Util.summarise_characteristics(shelf)
  end

  test "auto assign line cards" do
    places = [create_esa_place()]
    parties = [create_provider_party()]

    {:ok, shelf} = Access.build_shelf(%{name: "QDONC-0001", places: places, parties: parties})

    updates = [
      shelf: [device_name: "QDONC-1001", family: :ISAM, model: "ISAM7330", technology: :DSLAM],
      slots: [first: 1, last: 10, assignable_type: "LineCard"]
    ]

    {:ok, shelf} = Access.define_shelf(shelf, %{characteristic_value_updates: updates})

    line_card1 = create_line_card("lc1")
    {:ok, shelf} = Access.assign_slot(shelf, %{assignment: line_card1})
    line_card2 = create_line_card("lc2")
    {:ok, shelf} = Access.assign_slot(shelf, %{assignment: line_card2})

    Characteristics.check_values([slots: [free: 8]], shelf)

    encoding =
      Jason.encode!(shelf)
      |> Diffo.Util.summarise_dates()
      |> Util.summarise_characteristics(shelf)

    lc1 = line_card1.assignee_id
    lc2 = line_card2.assignee_id

    assert encoding ==
             ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{shelf.id}",\"category\":\"Network Resource\",\"description\":\"A Shelf Resource Instance which contain cards\",\"name\":\"QDONC-0001\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{lc1}\",\"href\":\"resourceInventoryManagement/v4/resource/#{lc1}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"slot\",\"value\":1}]},{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{lc2}\",\"href\":\"resourceInventoryManagement/v4/resource/#{lc2}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"slot\",\"value\":2}]}],\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{\"name\":\"QDONC-1001\",\"family\":\"ISAM\",\"model\":\"ISAM7330\",\"technology\":\"DSLAM\"}},{\"name\":\"slots\",\"value\":{\"first\":1,\"last\":10,\"free\":8,\"type\":\"LineCard\",\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
             |> Util.summarise_characteristics(shelf)
  end

  defp create_common_cards() do
    psu1 = create_common_card("psu1")
    psu2 = create_common_card("psu2")
    transport1 = create_common_card("transport1")
    transport2 = create_common_card("transport2")
    [psu1, psu2, transport1, transport2]
  end

  defp create_line_card(name) do
    card =
      Access.build_card!(%{name: "#{name}"})

    %Assignment{assignee_id: card.id, operation: :auto_assign}
  end

  defp create_common_card(name) do
    card =
      Access.build_card!(%{name: "#{name}"})

    %Relationship{id: card.id, direction: :forward, type: :contains}
  end

  defp create_esa_place do
    esa =
      Provider.create_place!(%{
        id: "DONC-0001",
        name: :esaId,
        href: "place/telco/DONC-0001",
        referred_type: :GeographicLocation
      })

    %Place{id: esa.id, role: :ServingArea}
  end

  defp create_provider_party do
    provider =
      Provider.create_party!(%{
        id: "Access",
        name: :organizationId,
        referred_type: :Organization
      })

    %Party{id: provider.id, role: :Provider}
  end
end

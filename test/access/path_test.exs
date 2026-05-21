# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.PathTest do
  @moduledoc false
  use DiffoExample.DataCase, async: true

  alias Diffo.Provider
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Assignment
  alias DiffoExample.Access
  alias DiffoExample.Access.Path
  alias DiffoExample.Test.Parties
  alias DiffoExample.Test.Places
  alias DiffoExample.Util

  describe "build path" do
    test "create a path" do
      places = [create_customer_place(), create_exchange_place(), create_esa_place()]
      parties = [create_provider_party()]

      {:ok, path} =
        Access.build_path(%{name: "82 Rathmullen - DONC", places: places, parties: parties})

      # check the instance is a Path
      assert is_struct(path, Path)

      # check specification resource enrichment and node relationship
      refute is_nil(path.specification_id)
      assert is_struct(path.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: path.id},
               :Specification,
               %{uuid: path.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # typed characteristics are not in instance.characteristics
      assert is_list(path.characteristics)
      assert length(path.characteristics) == 0

      Places.check_places(places, path)
      Parties.check_parties(parties, path)

      encoding =
        Jason.encode!(path)
        |> Diffo.Util.summarise_dates()
        |> Util.summarise_characteristics(path)

      assert encoding ==
               ~s({\"id\":\"#{path.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{path.id}",\"category\":\"Network Resource\",\"description\":\"A Path Resource Instance\",\"name\":\"82 Rathmullen - DONC\",\"resourceSpecification\":{\"id\":\"1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"name\":\"path\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"path\",\"value\":{\"sections\":0}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telco/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC\",\"href\":\"place/telco/DONC\",\"name\":\"exchangeId\",\"role\":\"NetworkSite\",\"@referredType\":\"GeographicSite\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
               |> Util.summarise_characteristics(path)
    end
  end

  test "define path" do
    places = [create_customer_place(), create_exchange_place(), create_esa_place()]
    parties = [create_provider_party()]

    {:ok, path} =
      Access.build_path(%{name: "82 Rathmullen - DONC", places: places, parties: parties})

    updates = [
      path: [device_name: "82 Rathmullen - DONC", technology: :copper]
    ]

    {:ok, path} = Access.define_path(path, %{characteristic_value_updates: updates})

    encoding =
      Jason.encode!(path)
      |> Diffo.Util.summarise_dates()
      |> Util.summarise_characteristics(path)

    assert encoding ==
             ~s({\"id\":\"#{path.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{path.id}",\"category\":\"Network Resource\",\"description\":\"A Path Resource Instance\",\"name\":\"82 Rathmullen - DONC\",\"resourceSpecification\":{\"id\":\"1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"name\":\"path\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"path\",\"value\":{\"name\":\"82 Rathmullen - DONC\",\"sections\":0,\"technology\":\"copper\"}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telco/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC\",\"href\":\"place/telco/DONC\",\"name\":\"exchangeId\",\"role\":\"NetworkSite\",\"@referredType\":\"GeographicSite\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
             |> Util.summarise_characteristics(path)
  end

  test "relate cables and dslam" do
    places = [create_customer_place(), create_exchange_place(), create_esa_place()]
    parties = [create_provider_party()]

    {:ok, path} =
      Access.build_path(%{name: "82 Rathmullen - DONC", places: places, parties: parties})

    updates = [
      path: [device_name: "82 Rathmullen - DONC", technology: :copper]
    ]

    {:ok, path} = Access.define_path(path, %{characteristic_value_updates: updates})

    cables = create_cables(places)

    # now assign a pair from each cable
    _cables =
      Enum.into(cables, [], fn cable ->
        Access.assign_pair!(cable, %{
          assignment: %Assignment{assignee_id: path.id, operation: :auto_assign}
        })
      end)

    # now assign a port from a line card
    [_dslam, line_card] = create_dslam_with_line_card("QDONC-0001", tl(places), parties)

    Access.assign_port!(line_card, %{
      assignment: %Assignment{assignee_id: path.id, operation: :auto_assign}
    })

    # 5 cables each assigned a pair to the path, plus 1 line card assigned a port
    # — six AssignmentRelationship records pointing at the path
    {:ok, incoming} =
      Diffo.Provider.AssignmentRelationship
      |> Ash.Query.filter_input(target_id: path.id)
      |> Ash.read()

    assert length(incoming) == 6

    {:ok, path} = Access.get_path_by_id(path.id)

    encoding =
      Jason.encode!(path)
      |> Diffo.Util.summarise_dates()
      |> Util.summarise_characteristics(path)

    # the reverse relationships are not encoded to json
    assert encoding ==
             ~s({\"id\":\"#{path.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{path.id}",\"category\":\"Network Resource\",\"description\":\"A Path Resource Instance\",\"name\":\"82 Rathmullen - DONC\",\"resourceSpecification\":{\"id\":\"1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"name\":\"path\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"path\",\"value\":{\"name\":\"82 Rathmullen - DONC\",\"sections\":0,\"technology\":\"copper\"}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telco/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC\",\"href\":\"place/telco/DONC\",\"name\":\"exchangeId\",\"role\":\"NetworkSite\",\"@referredType\":\"GeographicSite\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
             |> Util.summarise_characteristics(path)
  end

  defp create_customer_place do
    z_end =
      Provider.create_place!(%{
        id: "1657363",
        name: :addressId,
        href: "place/telco/1657363",
        referred_type: :GeographicAddress
      })

    %Place{id: z_end.id, role: :CustomerSite}
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

  defp create_exchange_place do
    exchange =
      Provider.create_place!(%{
        id: "DONC",
        name: :exchangeId,
        href: "place/telco/DONC",
        referred_type: :GeographicSite
      })

    %Place{id: exchange.id, role: :NetworkSite}
  end

  defp create_cables(places) do
    [z_end, exchange, _esa] = places
    tie = create_cable("QDONC-0001 line card 1 tie cable", [], [])

    main =
      create_cable(
        "DONC-0001-001 Lawford St main cable",
        [%Relationship{id: tie.id, direction: :forward, type: :connectedTo}],
        [z_end]
      )

    secondary =
      create_cable(
        "DONC-0001-005 North Rathmullen Quad cable",
        [%Relationship{id: main.id, direction: :forward, type: :connectedTo}],
        []
      )

    tertiary =
      create_cable(
        "DONC-0001-013 Rathmullen Quad East cable",
        [%Relationship{id: secondary.id, direction: :forward, type: :connectedTo}],
        []
      )

    lead_in =
      create_cable(
        "82 Rathmullen lead in",
        [%Relationship{id: tertiary.id, direction: :forward, type: :connectedTo}],
        [exchange]
      )

    [tie, main, secondary, tertiary, lead_in]
  end

  defp create_cable(name, relationships, places)
       when is_bitstring(name) and is_list(relationships) and is_list(places) do
    cable = Access.build_cable!(%{name: "#{name}", places: places, relationships: relationships})

    Access.define_cable!(cable, %{
      characteristic_value_updates: [pairs: [first: 1, last: 60, assignable_type: "copper"]]
    })
  end

  defp create_dslam_with_line_card(name, places, parties) when is_bitstring(name) do
    shelf = Access.build_shelf!(%{name: "dslam shelf #{name}", places: places, parties: parties})

    shelf =
      Access.define_shelf!(shelf, %{
        characteristic_value_updates: [slots: [first: 1, last: 10, assignable_type: "LineCard"]]
      })

    card = Access.build_card!(%{name: "dslam line card #{name} 1"})

    card =
      Access.define_card!(card, %{
        characteristic_value_updates: [ports: [first: 1, last: 48, assignable_type: "ADSL2+"]]
      })

    Access.assign_slot!(shelf, %{
      assignment: %Assignment{assignee_id: card.id, operation: :auto_assign}
    })

    [shelf, card]
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

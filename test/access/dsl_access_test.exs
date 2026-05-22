# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.DslAccessTest do
  @moduledoc false
  use DiffoExample.DataCase, async: true

  alias Diffo.Provider
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Feature
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias DiffoExample.Access
  alias DiffoExample.Access.DslAccess
  alias DiffoExample.Test.Parties
  alias DiffoExample.Test.Places

  describe "service qualification" do
    test "create an initial service for service qualification" do
      parties = create_initial_parties()
      places = [create_initial_place()]

      {:ok, dsl_access} = Access.qualify_dsl(%{parties: parties, places: places})

      # check the instance is a DslAccess
      assert is_struct(dsl_access, DslAccess)

      # check specification resource enrichment and node relationship
      refute is_nil(dsl_access.specification_id)
      assert is_struct(dsl_access.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: dsl_access.id},
               :Specification,
               %{uuid: dsl_access.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # check features resource enrichment and node relationships
      assert is_list(dsl_access.features)
      assert length(dsl_access.features) == 1

      Enum.each(dsl_access.features, fn feature ->
        assert is_struct(feature, Feature)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: dsl_access.id},
                 :Feature,
                 %{uuid: feature.id},
                 :HAS,
                 :outgoing
               )

        # typed characteristics are not in feature.characteristics
        assert is_list(feature.characteristics)
        assert length(feature.characteristics) == 0
      end)

      # typed characteristics are not in instance.characteristics
      assert is_list(dsl_access.characteristics)
      assert length(dsl_access.characteristics) == 0

      Parties.check_parties(parties, dsl_access)
      Places.check_places(places, dsl_access)

      encoding =
        Jason.encode!(dsl_access)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{dsl_access.id}",\"href\":\"serviceInventoryManagement/v4/service/#{dsl_access.id}\",\"category\":\"Network Service\",\"description\":\"A DSL Access Network Service connecting a subscriber premises to an NNI\",\"serviceSpecification\":{\"id\":\"da9b207a-26c3-451d-8abd-0640c6349979\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/da9b207a-26c3-451d-8abd-0640c6349979\",\"name\":\"dslAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"initial\",\"feature\":[{\"name\":\"dynamic_line_management\",\"isEnabled\":true}],\"serviceCharacteristic\":[{\"name\":\"dslam\",\"value\":{}},{\"name\":\"aggregate_interface\",\"value\":{}},{\"name\":\"circuit\",\"value\":{}},{\"name\":\"line\",\"value\":{}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telco/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"IND000000897354\",\"name\":\"individualId\",\"role\":\"Customer\",\"@referredType\":\"Individual\",\"@type\":\"PartyRef\"},{\"id\":\"ORG000000123456\",\"name\":\"organizationId\",\"role\":\"Reseller\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end

    test "advance service to feasibilityChecked" do
      initial_parties = create_initial_parties()
      initial_place = create_initial_place()

      {:ok, dsl_access} = Access.qualify_dsl(%{parties: initial_parties, places: [initial_place]})

      esa_place = create_esa_place()

      {:ok, dsl_access} =
        Access.qualify_dsl_result(dsl_access, %{
          service_operating_status: :feasible,
          places: [esa_place]
        })

      # check the instance is a DslAccess
      assert is_struct(dsl_access, DslAccess)

      assert dsl_access.service_state == :feasibilityChecked
      assert dsl_access.service_operating_status == :feasible

      Places.check_places([initial_place | [esa_place]], dsl_access)

      encoding =
        Jason.encode!(dsl_access)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{dsl_access.id}",\"href\":\"serviceInventoryManagement/v4/service/#{dsl_access.id}\",\"category\":\"Network Service\",\"description\":\"A DSL Access Network Service connecting a subscriber premises to an NNI\",\"serviceSpecification\":{\"id\":\"da9b207a-26c3-451d-8abd-0640c6349979\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/da9b207a-26c3-451d-8abd-0640c6349979\",\"name\":\"dslAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"feasibilityChecked\",\"operatingStatus\":\"feasible\",\"feature\":[{\"name\":\"dynamic_line_management\",\"isEnabled\":true}],\"serviceCharacteristic\":[{\"name\":\"dslam\",\"value\":{}},{\"name\":\"aggregate_interface\",\"value\":{}},{\"name\":\"circuit\",\"value\":{}},{\"name\":\"line\",\"value\":{}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telco/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"IND000000897354\",\"name\":\"individualId\",\"role\":\"Customer\",\"@referredType\":\"Individual\",\"@type\":\"PartyRef\"},{\"id\":\"ORG000000123456\",\"name\":\"organizationId\",\"role\":\"Reseller\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end
  end

  describe "service activation" do
    test "design the service" do
      initial_parties = create_initial_parties()
      initial_place = create_initial_place()
      {:ok, dsl_access} = Access.qualify_dsl(%{parties: initial_parties, places: [initial_place]})
      esa_place = create_esa_place()

      {:ok, dsl_access} =
        Access.qualify_dsl_result(dsl_access, %{
          service_operating_status: :feasible,
          places: [esa_place]
        })

      # now we design the circuit, allocating the dslam, slot, port
      # and we allocate the backhaul interface, svlan and cvlan, so can derive the cicuit id

      updates = [
        dslam: [device_name: "QDONC0001", model: "ISAM7330"],
        aggregate_interface: [interface_name: "eth0", svlan_id: 3108],
        circuit: [cvlan_id: 82],
        line: [slot: 10, port: 5]
      ]

      {:ok, dsl_access} =
        Access.design_dsl_result(dsl_access, %{characteristic_value_updates: updates})

      # check the instance is a DslAccess
      assert is_struct(dsl_access, DslAccess)

      assert dsl_access.service_state == :reserved
      assert dsl_access.service_operating_status == :feasible

      Places.check_places([initial_place | [esa_place]], dsl_access)

      encoding =
        Jason.encode!(dsl_access)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{dsl_access.id}",\"href\":\"serviceInventoryManagement/v4/service/#{dsl_access.id}\",\"category\":\"Network Service\",\"description\":\"A DSL Access Network Service connecting a subscriber premises to an NNI\",\"serviceSpecification\":{\"id\":\"da9b207a-26c3-451d-8abd-0640c6349979\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/da9b207a-26c3-451d-8abd-0640c6349979\",\"name\":\"dslAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"reserved\",\"operatingStatus\":\"feasible\",\"feature\":[{\"name\":\"dynamic_line_management\",\"isEnabled\":true}],\"serviceCharacteristic\":[{\"name\":\"dslam\",\"value\":{\"name\":\"QDONC0001\",\"model\":\"ISAM7330\"}},{\"name\":\"aggregate_interface\",\"value\":{\"name\":\"eth0\",\"svlanId\":3108}},{\"name\":\"circuit\",\"value\":{\"cvlan_id\":82}},{\"name\":\"line\",\"value\":{\"port\":5,\"slot\":10}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telco/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telco/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"IND000000897354\",\"name\":\"individualId\",\"role\":\"Customer\",\"@referredType\":\"Individual\",\"@type\":\"PartyRef\"},{\"id\":\"ORG000000123456\",\"name\":\"organizationId\",\"role\":\"Reseller\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end
  end

  defp create_initial_place do
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

  defp create_initial_parties do
    individual =
      Provider.create_party!(%{
        id: "IND000000897354",
        name: :individualId,
        referred_type: :Individual
      })

    org =
      Provider.create_party!(%{
        id: "ORG000000123456",
        name: :organizationId,
        referred_type: :Organization
      })

    [%Party{id: individual.id, role: :Customer}, %Party{id: org.id, role: :Reseller}]
  end
end

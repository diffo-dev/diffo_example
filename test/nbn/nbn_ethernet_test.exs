# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NbnEthernetTest do
  @moduledoc false
  use DiffoExample.DataCase, async: true

  alias Diffo.Provider.Specification
  alias DiffoExample.Nbn
  alias DiffoExample.Nbn.NbnEthernet
  alias DiffoExample.Nbn.Uni
  alias DiffoExample.Nbn.Avc
  alias DiffoExample.Nbn.Ntd
  alias DiffoExample.Nbn.Cvc
  alias DiffoExample.Nbn.NniGroup
  alias DiffoExample.Nbn.Nni
  alias DiffoExample.Test.Characteristics
  alias Diffo.Provider.Assignment
  alias Diffo.Provider.Instance.Relationship

  describe "build nbn_ethernet" do
    test "create an nbn_ethernet access" do
      {:ok, access} = Nbn.build_nbn_ethernet(%{})

      # check the instance is an NbnEthernet
      assert is_struct(access, NbnEthernet)

      # check specification resource enrichment and node relationship
      refute is_nil(access.specification_id)
      assert is_struct(access.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: access.id},
               :Specification,
               %{uuid: access.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # typed characteristics are not in instance.characteristics
      assert is_list(access.characteristics)
      assert length(access.characteristics) == 0

      encoding =
        Jason.encode!(access)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({"id":"#{access.id}","href":"resourceInventoryManagement/v4/resource/#{access.id}","category":"Network Resource","description":"An NBN Ethernet access comprising a dedicated UNI and AVC",\"name\":\"#{access.name}","resourceSpecification":{"id":"f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","href":"resourceCatalogManagement/v4/resourceSpecification/f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","name":"nbnEthernet","version":"v1.0.0"},"resourceCharacteristic":[{"name":"pri","value":{}}]})
    end

    test "define nbn_ethernet access" do
      {:ok, access} = Nbn.build_nbn_ethernet(%{})

      updates = [
        pri: [
          avcid: "AVC000910202941",
          uniid: "UNI000302814545",
          speeds_downstream: 500,
          speeds_upstream: 50,
          technology: :FTTP
        ]
      ]

      {:ok, access} = Nbn.define_nbn_ethernet(access, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [
          pri: [
            avcid: "AVC000910202941",
            uniid: "UNI000302814545",
            speeds: %{downstream: 500, upstream: 50, units: "Mbps"},
            technology: :FTTP
          ]
        ],
        access
      )
    end

    test "relate nbn_ethernet" do
      {:ok, access} = Nbn.build_nbn_ethernet(%{})

      {:ok, nni_group} = Nbn.build_nni_group(%{})

      {:ok, nni_group} =
        Nbn.define_nni_group(nni_group, %{
          characteristic_value_updates: [svlans: [first: 1, last: 4000, assignable_type: "svlan"]]
        })

      {:ok, cvc} = Nbn.build_cvc(%{})

      {:ok, cvc} =
        Nbn.define_cvc(cvc, %{
          characteristic_value_updates: [cvlans: [first: 1, last: 4000, assignable_type: "cvlan"]]
        })

      {:ok, _nni_group} =
        Nbn.assign_svlan(nni_group, %{
          assignment: %Assignment{assignee_id: cvc.id, operation: :auto_assign}
        })

      {:ok, cvc} = Nbn.get_cvc_by_id(cvc.id, load: [:reverse_relationships])

      {:ok, avc} = Nbn.build_avc(%{})

      {:ok, avc} =
        Nbn.define_avc(avc, %{
          characteristic_value_updates: [avc: [bandwidth_profile: :home_fast]]
        })

      {:ok, _cvc} =
        Nbn.assign_cvlan(cvc, %{
          assignment: %Assignment{assignee_id: avc.id, operation: :auto_assign}
        })

      {:ok, avc} = Nbn.get_avc_by_id(avc.id, load: [:reverse_relationships])

      {:ok, ntd} = Nbn.build_ntd(%{})

      {:ok, ntd} =
        Nbn.define_ntd(ntd, %{characteristic_value_updates: [ntd: [technology: :FTTP]]})

      {:ok, uni} = Nbn.build_uni(%{})

      {:ok, _ntd} =
        Nbn.assign_port(ntd, %{
          assignment: %Assignment{assignee_id: uni.id, operation: :auto_assign}
        })

      {:ok, uni} = Nbn.get_uni_by_id(uni.id, load: [:reverse_relationships])

      relationships = [
        %Relationship{id: avc.id, direction: :forward, type: :owns, alias: :avc},
        %Relationship{id: uni.id, direction: :forward, type: :owns, alias: :uni}
      ]

      {:ok, access} = Nbn.relate_nbn_ethernet(access, %{relationships: relationships})

      encoding =
        Jason.encode!(access)
        |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({"id":"#{access.id}","href":"resourceInventoryManagement/v4/resource/#{access.id}","category":"Network Resource","description":"An NBN Ethernet access comprising a dedicated UNI and AVC","name":"#{access.name}","resourceSpecification":{"id":"f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","href":"resourceCatalogManagement/v4/resourceSpecification/f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","name":"nbnEthernet","version":"v1.0.0"},"resourceRelationship":[{"alias":"avc","type":"owns","resource":{"id":"#{avc.id}","href":"resourceInventoryManagement/v4/resource/#{avc.id}"}},{"alias":"uni","type":"owns","resource":{"id\":"#{uni.id}","href":"resourceInventoryManagement/v4/resource/#{uni.id}"}}],"supportingResource":[{"id":"avc","href":"resourceInventoryManagement/v4/resource/#{avc.id}"},{"id\":"uni","href":"resourceInventoryManagement/v4/resource/#{uni.id}"}],"resourceCharacteristic":[{"name":"pri","value":{}}]})
    end
  end

  describe "build uni" do
    test "create a uni" do
      {:ok, uni} = Nbn.build_uni(%{})

      assert is_struct(uni, Uni)
      refute is_nil(uni.specification_id)
      assert is_struct(uni.specification, Specification)
      # typed characteristics are not in instance.characteristics
      assert is_list(uni.characteristics)
      assert length(uni.characteristics) == 0
    end

    test "define uni" do
      {:ok, uni} = Nbn.build_uni(%{})

      updates = [
        uni: [port: 1, encapsulation: "DSCP Mapped", technology: :FTTP]
      ]

      {:ok, uni} = Nbn.define_uni(uni, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [uni: [port: 1, encapsulation: "DSCP Mapped", technology: :FTTP]],
        uni
      )
    end
  end

  describe "build avc" do
    test "create an avc" do
      {:ok, avc} = Nbn.build_avc(%{})

      assert is_struct(avc, Avc)
      refute is_nil(avc.specification_id)
      assert is_struct(avc.specification, Specification)
      # typed characteristics are not in instance.characteristics
      assert is_list(avc.characteristics)
      assert length(avc.characteristics) == 0
    end

    test "define avc" do
      {:ok, avc} = Nbn.build_avc(%{})

      updates = [
        avc: [cvlan: 1, bandwidth_profile: :home_fast]
      ]

      {:ok, avc} = Nbn.define_avc(avc, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [avc: [cvlan: 1, bandwidth_profile: :home_fast]],
        avc
      )
    end

    test "avc inherits cvc (single-hop) and nni_group (two-hop) via assignment chain" do
      # NniGroup with svlan pool, then a CVC that takes an svlan from it,
      # then an AVC that takes a cvlan from the CVC. AVC's inherited calcs
      # should bring up cvc and nni_group characteristics.
      {:ok, nni_group} = Nbn.build_nni_group(%{})

      {:ok, nni_group} =
        Nbn.define_nni_group(nni_group, %{
          characteristic_value_updates: [
            nni_group: [group_name: "SYD-POI-01", location: "Sydney"],
            svlans: [first: 1, last: 4000, assignable_type: "svlan"]
          ]
        })

      {:ok, cvc} = Nbn.build_cvc(%{})

      {:ok, cvc} =
        Nbn.define_cvc(cvc, %{
          characteristic_value_updates: [
            cvc: [bandwidth: 1000],
            cvlans: [first: 1, last: 4000, assignable_type: "cvlan"]
          ]
        })

      {:ok, _nni_group} =
        Nbn.assign_svlan(nni_group, %{
          assignment: %Assignment{
            assignee_id: cvc.id,
            alias: :svlan,
            operation: :auto_assign
          }
        })

      {:ok, avc} = Nbn.build_avc(%{})

      {:ok, _avc} =
        Nbn.define_avc(avc, %{
          characteristic_value_updates: [avc: [bandwidth_profile: :home_fast]]
        })

      {:ok, _cvc} =
        Nbn.assign_cvlan(cvc, %{
          assignment: %Assignment{
            assignee_id: avc.id,
            alias: :cvlan,
            operation: :auto_assign
          }
        })

      {:ok, avc} = Nbn.get_avc_by_id(avc.id, load: [:cvc, :nni_group])

      assert %{bandwidth: 1000} = avc.cvc
      assert %{group_name: "SYD-POI-01", location: "Sydney"} = avc.nni_group
    end
  end

  describe "build ntd" do
    test "create an ntd" do
      {:ok, ntd} = Nbn.build_ntd(%{})

      assert is_struct(ntd, Ntd)
      refute is_nil(ntd.specification_id)
    end

    test "define ntd and assign ports to unis" do
      {:ok, ntd} = Nbn.build_ntd(%{})

      updates = [
        ntd: [model: "Sercomm CG4000A", serial_number: "SCOMA1A057A2", technology: :FTTP],
        ports: [first: 1, last: 4, assignable_type: "port"]
      ]

      {:ok, ntd} = Nbn.define_ntd(ntd, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [
          ntd: [model: "Sercomm CG4000A", serial_number: "SCOMA1A057A2", technology: :FTTP],
          ports: [first: 1, last: 4, free: 4, assignable_type: "port"]
        ],
        ntd
      )

      {:ok, ntd} = Nbn.assign_port(ntd, %{assignment: create_uni()})
      {:ok, ntd} = Nbn.assign_port(ntd, %{assignment: create_uni()})

      Characteristics.check_values(
        [
          ntd: [model: "Sercomm CG4000A", serial_number: "SCOMA1A057A2", technology: :FTTP],
          ports: [first: 1, last: 4, free: 2, assignable_type: "port"]
        ],
        ntd
      )

      # mine and check each uni
      Enum.each(ntd.forward_relationships, fn relationship ->
        {:ok, uni} =
          Nbn.get_uni_by_id(relationship.target_id, load: [:reverse_relationships])

        # uni should have an uni characteristic with the port
        Characteristics.check_values(
          [
            uni: [port: &Outstand.any_integer/1]
          ],
          uni
        )
      end)
    end

    test "ntd brings up assigned UNIs as unis[] via :port assignment" do
      {:ok, ntd} = Nbn.build_ntd(%{})

      {:ok, ntd} =
        Nbn.define_ntd(ntd, %{
          characteristic_value_updates: [
            ntd: [model: "Sercomm CG4000A", technology: :FTTP],
            ports: [first: 1, last: 4, assignable_type: "port"]
          ]
        })

      # Two UNIs defined and assigned ports from the NTD
      for {port_num, encap} <- [{1, "DSCP Mapped"}, {2, "untagged"}] do
        {:ok, uni} = Nbn.build_uni(%{})

        {:ok, _} =
          Nbn.define_uni(uni, %{
            characteristic_value_updates: [
              uni: [port: port_num, encapsulation: encap, technology: :FTTP]
            ]
          })

        {:ok, _} =
          Nbn.assign_port(ntd, %{
            assignment: %Assignment{assignee_id: uni.id, operation: :auto_assign}
          })
      end

      {:ok, ntd} = Nbn.get_ntd_by_id(ntd.id, load: [:unis])

      assert is_list(ntd.unis)
      assert length(ntd.unis) == 2

      ports = Enum.map(ntd.unis, & &1.port) |> Enum.sort()
      assert ports == [1, 2]
    end
  end

  describe "build cvc" do
    test "create a cvc" do
      {:ok, cvc} = Nbn.build_cvc(%{})

      assert is_struct(cvc, Cvc)
      refute is_nil(cvc.specification_id)
    end

    test "define cvc and assign cvlans to avcs" do
      {:ok, cvc} = Nbn.build_cvc(%{})

      updates = [
        cvc: [svlan: 1, bandwidth: 10000],
        cvlans: [first: 1, last: 4000, assignable_type: "cvlan"]
      ]

      {:ok, cvc} = Nbn.define_cvc(cvc, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [
          cvc: [svlan: 1, bandwidth: 10000],
          cvlans: [first: 1, last: 4000, free: 4000, assignable_type: "cvlan"]
        ],
        cvc
      )

      {:ok, cvc} = Nbn.assign_cvlan(cvc, %{assignment: create_avc()})
      {:ok, cvc} = Nbn.assign_cvlan(cvc, %{assignment: create_avc()})

      Characteristics.check_values(
        [
          cvc: [svlan: 1, bandwidth: 10000],
          cvlans: [first: 1, last: 4000, free: 3998, assignable_type: "cvlan"]
        ],
        cvc
      )

      # mine and check each avc
      Enum.each(cvc.forward_relationships, fn relationship ->
        {:ok, avc} =
          Nbn.get_avc_by_id(relationship.target_id, load: [:reverse_relationships])

        # avc should have an avc characteristic with the cvlan
        Characteristics.check_values(
          [
            avc: [cvlan: &Outstand.any_integer/1],
            cvc: [svlan: :no_value]
          ],
          avc
        )
      end)
    end

    test "cvc metrics aggregates avcs_count and avcs_total_bandwidth across assigned avcs" do
      {:ok, cvc} = Nbn.build_cvc(%{})

      {:ok, cvc} =
        Nbn.define_cvc(cvc, %{
          characteristic_value_updates: [
            cvc: [svlan: 1, bandwidth: 10000],
            cvlans: [first: 1, last: 4000, assignable_type: "cvlan"]
          ]
        })

      # Two AVCs with distinct bandwidth_profiles — :home_fast (500 Mbps
      # downstream) and :D100_U40 (100 Mbps downstream).
      for profile <- [:home_fast, :D100_U40] do
        {:ok, avc} = Nbn.build_avc(%{})

        {:ok, _} =
          Nbn.define_avc(avc, %{
            characteristic_value_updates: [avc: [bandwidth_profile: profile]]
          })

        {:ok, _} =
          Nbn.assign_cvlan(cvc, %{
            assignment: %Assignment{assignee_id: avc.id, operation: :auto_assign}
          })
      end

      metrics =
        DiffoExample.Nbn.CvcMetrics
        |> Ash.Query.filter_input(instance_id: cvc.id)
        |> Ash.Query.load(:value)
        |> Ash.read_one!()

      assert metrics.value.avcs_count == 2
      assert metrics.value.avcs_total_bandwidth == 600
    end
  end

  describe "build nni_group" do
    test "create an nni_group" do
      {:ok, nni_group} = Nbn.build_nni_group(%{})

      assert is_struct(nni_group, NniGroup)
      refute is_nil(nni_group.specification_id)
    end

    test "define nni_group and assign svlans to cvcs" do
      {:ok, nni_group} = Nbn.build_nni_group(%{})

      updates = [
        nni_group: [group_name: "SYD-POI-01", location: "Sydney Olympic Park"],
        svlans: [first: 1, last: 4000, assignable_type: "svlan"]
      ]

      {:ok, nni_group} =
        Nbn.define_nni_group(nni_group, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [
          nni_group: [group_name: "SYD-POI-01", location: "Sydney Olympic Park"],
          svlans: [first: 1, last: 4000, free: 4000, assignable_type: "svlan"]
        ],
        nni_group
      )

      {:ok, nni_group} = Nbn.assign_svlan(nni_group, %{assignment: create_cvc()})
      {:ok, nni_group} = Nbn.assign_svlan(nni_group, %{assignment: create_cvc()})

      Characteristics.check_values(
        [
          nni_group: [group_name: "SYD-POI-01", location: "Sydney Olympic Park"],
          svlans: [first: 1, last: 4000, free: 3998, assignable_type: "svlan"]
        ],
        nni_group
      )

      Enum.each(nni_group.forward_relationships, fn relationship ->
        {:ok, cvc} =
          Nbn.get_cvc_by_id(relationship.target_id, load: [:reverse_relationships])

        # cvc should have a cvc characteristic with the svlan
        Characteristics.check_values(
          [
            cvc: [svlan: &Outstand.any_integer/1]
          ],
          cvc
        )
      end)
    end

    test "nni_group metrics — cvcs and nnis aggregates plus utilization" do
      {:ok, nni_group} = Nbn.build_nni_group(%{})

      {:ok, nni_group} =
        Nbn.define_nni_group(nni_group, %{
          characteristic_value_updates: [
            nni_group: [group_name: "SYD-POI-01", location: "Sydney"],
            svlans: [first: 1, last: 4000, assignable_type: "svlan"]
          ]
        })

      # Demand side: two CVCs assigned svlans from this NniGroup.
      for bandwidth <- [400, 600] do
        {:ok, cvc} = Nbn.build_cvc(%{})

        {:ok, _} =
          Nbn.define_cvc(cvc, %{
            characteristic_value_updates: [cvc: [bandwidth: bandwidth]]
          })

        {:ok, _} =
          Nbn.assign_svlan(nni_group, %{
            assignment: %Assignment{assignee_id: cvc.id, operation: :auto_assign}
          })
      end

      # Capacity side: two NNIs comprised by this NniGroup, related via
      # DefinedSimpleRelationship type :contains.
      nni_ids =
        for capacity <- [10, 10] do
          {:ok, nni} = Nbn.build_nni(%{})

          {:ok, _} =
            Nbn.define_nni(nni, %{
              characteristic_value_updates: [
                nni: [port_id: "SYD-01-ETH-#{capacity}", capacity: capacity]
              ]
            })

          nni.id
        end

      {:ok, _nni_group} =
        Nbn.relate_nni_group(nni_group, %{
          relationships:
            Enum.map(nni_ids, fn nni_id ->
              %Relationship{id: nni_id, direction: :forward, type: :contains}
            end)
        })

      metrics =
        DiffoExample.Nbn.NniGroupMetrics
        |> Ash.Query.filter_input(instance_id: nni_group.id)
        |> Ash.Query.load(:value)
        |> Ash.read_one!()

      assert metrics.value.cvcs_count == 2
      assert metrics.value.cvcs_total_bandwidth == 1000
      assert metrics.value.nnis_count == 2
      assert metrics.value.nnis_total_bandwidth == 20
      assert_in_delta metrics.value.utilization, 50.0, 0.001

      # nnis[] brings up the NNI characteristic of every comprised NNI via
      # the same :contains relationships.
      {:ok, nni_group} = Nbn.get_nni_group_by_id(nni_group.id, load: [:nnis])

      assert is_list(nni_group.nnis)
      assert length(nni_group.nnis) == 2

      assert Enum.all?(nni_group.nnis, &match?(%{capacity: 10}, &1))
    end
  end

  describe "build nni" do
    test "create an nni" do
      {:ok, nni} = Nbn.build_nni(%{})

      assert is_struct(nni, Nni)
      refute is_nil(nni.specification_id)
    end

    test "define nni" do
      {:ok, nni} = Nbn.build_nni(%{})

      updates = [
        nni: [port_id: "SYD-01-ETH-001", capacity: 10, technology: :Ethernet]
      ]

      {:ok, nni} = Nbn.define_nni(nni, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [nni: [port_id: "SYD-01-ETH-001", capacity: 10, technology: :Ethernet]],
        nni
      )
    end
  end

  defp create_uni() do
    {:ok, uni} = Nbn.build_uni(%{})
    %Assignment{assignee_id: uni.id, operation: :auto_assign}
  end

  defp create_cvc() do
    {:ok, cvc} = Nbn.build_cvc(%{})
    %Assignment{assignee_id: cvc.id, operation: :auto_assign}
  end

  defp create_avc() do
    {:ok, avc} = Nbn.build_avc(%{})
    %Assignment{assignee_id: avc.id, operation: :auto_assign}
  end
end

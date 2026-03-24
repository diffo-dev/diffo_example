# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NbnEthernetTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias DiffoExample.Nbn
  alias DiffoExample.Nbn.NbnEthernet
  alias DiffoExample.Nbn.Uni
  alias DiffoExample.Nbn.Avc
  alias DiffoExample.Nbn.Ntd
  alias DiffoExample.Nbn.Cvc
  alias DiffoExample.Nbn.NniGroup
  alias DiffoExample.Nbn.Nni
  alias DiffoExample.Test.Characteristics
  alias Diffo.Provider.Instance.Relationship

  setup_all do
    AshNeo4j.BoltyHelper.start()
  end

  setup do
    # on_exit(fn ->
    #  AshNeo4j.Neo4jHelper.delete_all()
    # end)
    :ok
  end

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

      # check characteristic resource enrichment and node relationships
      assert is_list(access.characteristics)
      assert length(access.characteristics) == 1

      Enum.each(access.characteristics, fn characteristic ->
        assert is_struct(characteristic, Characteristic)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: access.id},
                 :Characteristic,
                 %{uuid: characteristic.id},
                 :HAS,
                 :outgoing
               )
      end)

      encoding = Jason.encode!(access) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({"id":"#{access.id}","href":"resourceInventoryManagement/v4/resource/nbnEthernet/#{access.id}","category":"Network Resource",\"name\":\"#{access.name}","resourceSpecification":{"id":"f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","href":"resourceCatalogManagement/v4/resourceSpecification/f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","name":"nbnEthernet","version":"v1.0.0"},"resourceCharacteristic":[{"name":"pri","value":{\"technology\":\"FTTP\"}}]})
    end

    test "define nbn_ethernet access" do
      {:ok, access} = Nbn.build_nbn_ethernet(%{})

      updates = [
        pri: [avcid: "AVC000910202941", uniid: "UNI000302814545", speed: 1000, technology: :FTTP]
      ]

      {:ok, access} = Nbn.define_nbn_ethernet(access, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [pri: [avcid: "AVC000910202941", uniid: "UNI000302814545", speed: 1000, technology: :FTTP]],
        access
      )
    end

    test "relate nbn_ethernet" do
      {:ok, access} = Nbn.build_nbn_ethernet(%{})

      {:ok, avc} = Nbn.build_avc(%{})

      {:ok, uni} = Nbn.build_uni(%{})

      relationships = [
        %Relationship{id: avc.id, direction: :forward, type: :owns, alias: :avc},
        %Relationship{id: uni.id, direction: :forward, type: :owns, alias: :uni}
      ]

      {:ok, access} = Nbn.relate_nbn_ethernet(access, %{relationships: relationships})

      {:ok, access} = Nbn.mine_nbn_ethernet(access)

      encoding = Jason.encode!(access) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({"id":"#{access.id}","href":"resourceInventoryManagement/v4/resource/nbnEthernet/#{access.id}","category":"Network Resource","name":"#{access.name}","resourceSpecification":{"id":"f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","href":"resourceCatalogManagement/v4/resourceSpecification/f2a4c6e8-1b3d-4f5a-8c7e-9d0b2e4f6a8c","name":"nbnEthernet","version":"v1.0.0"},"resourceRelationship":[{"alias":"avc","type":"owns","resource":{"id":"#{avc.id}","href":"resourceInventoryManagement/v4/resource/avc/#{avc.id}"}},{"alias":"uni","type":"owns","resource":{"id\":"#{uni.id}","href":"resourceInventoryManagement/v4/resource/uni/#{uni.id}"}}],"supportingResource":[{"id":"avc","href":"resourceInventoryManagement/v4/resource/avc/#{avc.id}"},{"id\":"uni","href":"resourceInventoryManagement/v4/resource/uni/#{uni.id}"}],"resourceCharacteristic":[{"name":"pri","value":{"avcid":"#{avc.name}","uniid":"#{uni.name}","technology":"FTTP"}}]})
    end
  end

  describe "build uni" do
    test "create a uni" do
      {:ok, uni} = Nbn.build_uni(%{})

      assert is_struct(uni, Uni)
      refute is_nil(uni.specification_id)
      assert is_struct(uni.specification, Specification)
      assert is_list(uni.characteristics)
      assert length(uni.characteristics) == 1
    end

    test "define uni" do
      {:ok, uni} = Nbn.build_uni(%{})

      updates = [
        uni: [vlan_id: 101, bandwidth_profile: "TC4", technology: :FTTP]
      ]

      {:ok, uni} = Nbn.define_uni(uni, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [uni: [vlan_id: 101, bandwidth_profile: "TC4", technology: :FTTP]],
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
      assert is_list(avc.characteristics)
      assert length(avc.characteristics) == 1
    end

    test "define avc" do
      {:ok, avc} = Nbn.build_avc(%{})

      updates = [
        avc: [cir: 100, pir: 1000]
      ]

      {:ok, avc} = Nbn.define_avc(avc, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [avc: [cir: 100, pir: 1000]],
        avc
      )
    end
  end

  describe "build ntd" do
    test "create an ntd" do
      {:ok, ntd} = Nbn.build_ntd(%{})

      assert is_struct(ntd, Ntd)
      refute is_nil(ntd.specification_id)
    end

    test "define ntd" do
      {:ok, ntd} = Nbn.build_ntd(%{})

      updates = [
        ntd: [model: "Arris CM8200", serial_number: "SN-ABC-123456", technology: :HFC]
      ]

      {:ok, ntd} = Nbn.define_ntd(ntd, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [ntd: [model: "Arris CM8200", serial_number: "SN-ABC-123456", technology: :HFC]],
        ntd
      )
    end
  end

  describe "build cvc" do
    test "create a cvc" do
      {:ok, cvc} = Nbn.build_cvc(%{})

      assert is_struct(cvc, Cvc)
      refute is_nil(cvc.specification_id)
    end

    test "define cvc" do
      {:ok, cvc} = Nbn.build_cvc(%{})

      updates = [
        cvc: [cvc_id: "CVC-POI-SYD-001", bandwidth: 10000]
      ]

      {:ok, cvc} = Nbn.define_cvc(cvc, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [cvc: [cvc_id: "CVC-POI-SYD-001", bandwidth: 10000]],
        cvc
      )
    end
  end

  describe "build nni_group" do
    test "create an nni_group" do
      {:ok, nni_group} = Nbn.build_nni_group(%{})

      assert is_struct(nni_group, NniGroup)
      refute is_nil(nni_group.specification_id)
    end

    test "define nni_group" do
      {:ok, nni_group} = Nbn.build_nni_group(%{})

      updates = [
        nni_group: [name: "SYD-POI-01", location: "Sydney Olympic Park"]
      ]

      {:ok, nni_group} =
        Nbn.define_nni_group(nni_group, %{characteristic_value_updates: updates})

      Characteristics.check_values(
        [nni_group: [name: "SYD-POI-01", location: "Sydney Olympic Park"]],
        nni_group
      )
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
end

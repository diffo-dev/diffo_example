# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.RspTest do
  @moduledoc false
  use ExUnit.Case
  alias DiffoExample.Nbn
  alias DiffoExample.Nbn.Rsp

  setup_all do
    AshNeo4j.BoltyHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  defp create_rsp(attrs) do
    {:ok, rsp} = Nbn.create_rsp(attrs)
    {:ok, rsp} = Nbn.activate_rsp(rsp)
    rsp
  end

  describe "RSP resource" do
    test "create and activate an RSP" do
      {:ok, rsp} = Nbn.create_rsp(%{name: "Wedge-tail Telecom", short_name: :wedgetail, id: "8001"})

      assert is_struct(rsp, Rsp)
      assert rsp.state == :inactive
      assert rsp.id == "8001"
      assert rsp.short_name == :wedgetail

      {:ok, rsp} = Nbn.activate_rsp(rsp)
      assert rsp.state == :active
    end

    test "RSP state machine: activate → suspend → deactivate" do
      {:ok, rsp} = Nbn.create_rsp(%{name: "Wedge-tail Telecom", short_name: :wedgetail, id: "8001"})

      {:ok, rsp} = Nbn.activate_rsp(rsp)
      assert rsp.state == :active

      {:ok, rsp} = Nbn.suspend_rsp(rsp)
      assert rsp.state == :suspended

      {:ok, rsp} = Nbn.deactivate_rsp(rsp)
      assert rsp.state == :inactive
    end

    test "id must be a four-digit EPID" do
      assert {:error, _} = Nbn.create_rsp(%{name: "Bad RSP", short_name: :bad, id: "123"})
      assert {:error, _} = Nbn.create_rsp(%{name: "Bad RSP", short_name: :bad, id: "12345"})
      assert {:error, _} = Nbn.create_rsp(%{name: "Bad RSP", short_name: :bad, id: "abcd"})
    end

    test "get RSP by short_name" do
      create_rsp(%{name: "Wedge-tail Telecom", short_name: :wedgetail, id: "8001"})

      {:ok, rsp} = Nbn.get_rsp_by_short_name(:wedgetail)
      assert rsp.short_name == :wedgetail
      assert rsp.id == "8001"
    end

    test "get RSP by epid" do
      create_rsp(%{name: "Quokka Connect", short_name: :quokka, id: "8002"})

      {:ok, rsp} = Nbn.get_rsp_by_epid("8002")
      assert rsp.short_name == :quokka
    end
  end

  describe "RSP multi-tenancy" do
    setup do
      wedgetail = create_rsp(%{name: "Wedge-tail Telecom", short_name: :wedgetail, id: "8001"})
      quokka = create_rsp(%{name: "Quokka Connect", short_name: :quokka, id: "8002"})
      %{wedgetail: wedgetail, quokka: quokka}
    end

    test "build stamps rsp_id from actor", %{wedgetail: wedgetail} do
      {:ok, resource} = Nbn.build_nbn_ethernet(%{}, actor: wedgetail)
      assert resource.rsp_id == wedgetail.id
    end

    test "build without actor leaves rsp_id nil" do
      {:ok, resource} = Nbn.build_nbn_ethernet(%{})
      assert is_nil(resource.rsp_id)
    end

    test "RSP can read its own resource", %{wedgetail: wedgetail} do
      {:ok, resource} = Nbn.build_nbn_ethernet(%{}, actor: wedgetail)
      assert {:ok, found} = Nbn.get_nbn_ethernet_by_id(resource.id, actor: wedgetail)
      assert found.id == resource.id
    end

    test "RSP cannot read another RSP's resource", %{wedgetail: wedgetail, quokka: quokka} do
      {:ok, resource} = Nbn.build_nbn_ethernet(%{}, actor: wedgetail)
      assert {:error, _} = Nbn.get_nbn_ethernet_by_id(resource.id, actor: quokka)
    end

    test "RSP cannot update another RSP's resource", %{wedgetail: wedgetail, quokka: quokka} do
      {:ok, resource} = Nbn.build_nbn_ethernet(%{}, actor: wedgetail)

      assert {:error, %Ash.Error.Forbidden{}} =
               Nbn.define_nbn_ethernet(resource, %{characteristic_value_updates: []}, actor: quokka)
    end

    test "nil actor (internal call) can read any RSP's resource", %{wedgetail: wedgetail} do
      {:ok, resource} = Nbn.build_nbn_ethernet(%{}, actor: wedgetail)
      assert {:ok, found} = Nbn.get_nbn_ethernet_by_id(resource.id)
      assert found.id == resource.id
    end

    test "admin actor can read any RSP's resource", %{wedgetail: wedgetail} do
      admin = %{id: Ash.UUID.generate(), role: :admin}
      {:ok, resource} = Nbn.build_nbn_ethernet(%{}, actor: wedgetail)
      assert {:ok, found} = Nbn.get_nbn_ethernet_by_id(resource.id, actor: admin)
      assert found.id == resource.id
    end

    test "two RSPs own separate resources", %{wedgetail: wedgetail, quokka: quokka} do
      {:ok, wt_resource} = Nbn.build_nbn_ethernet(%{}, actor: wedgetail)
      {:ok, qq_resource} = Nbn.build_nbn_ethernet(%{}, actor: quokka)

      assert wt_resource.rsp_id == wedgetail.id
      assert qq_resource.rsp_id == quokka.id
      refute wt_resource.rsp_id == qq_resource.rsp_id
    end
  end
end

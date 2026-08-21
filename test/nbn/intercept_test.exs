# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.InterceptTest do
  @moduledoc """
  Memorialises the lawful-intercept story shown in the NBN livebook (#60): from a
  customer's UNI, which network-edge NNIs could its traffic traverse?

  The seed (`DiffoExample.Nbn.ServiceInitializer`) lays down quokka's standing
  edge at 5STI — two NNI Groups (10G and 100G), four CVCs — and NBN's on-site
  NTD with four idle UNIs. Provisioning a service is the enacted journey: the RSP
  picks an idle UNI and a CVC (balancing load), and *that pick decides which NNIs
  the intercept returns*. Because `Uni.intercept_nnis` is a live graph traversal
  (UNI → PRI → AVC → CVC → NNI Group → NNIs), re-wiring moves the answer.

  If the livebook story would break, these tests break first.
  """
  use DiffoExample.DataCase, async: true

  alias DiffoExample.Nbn
  alias DiffoExample.Nbn.ServiceInitializer, as: SI

  setup do
    # The standing infrastructure — RSPs, geo places, the 5STI service edge — is
    # seeded once in test_helper.exs. Each test only rolls back its own writes.
    {:ok, quokka} = Nbn.get_rsp_by_short_name(:quokka)
    %{quokka: quokka}
  end

  describe "standing infrastructure" do
    test "the on-site NTD carries its LocationPoint (:locates) and Location (:addressed_at)" do
      {:ok, ntd} = Nbn.get_ntd_by_id(SI.ntd_id(), load: [places: [:place]])

      locates = Enum.find(ntd.places, &(&1.role == :locates))
      addressed = Enum.find(ntd.places, &(&1.role == :addressed_at))
      assert locates.place.id == SI.library_lop_id()
      assert addressed.place.id == SI.library_loc_id()
    end

    test "each NNI Group carries the 5STI POI (:locates) and its CSA (:serves)", %{quokka: quokka} do
      for group_id <- Map.values(SI.group_ids()) do
        {:ok, group} =
          Nbn.get_nni_group_by_id(group_id, load: [places: [:place]], actor: quokka)

        locates = Enum.find(group.places, &(&1.role == :locates))
        serves = Enum.find(group.places, &(&1.role == :serves))
        assert locates.place.id == SI.poi_id()
        assert serves.place.id == SI.csa_id()
      end
    end

    test "four idle UNIs are pre-built on the NTD" do
      {:ok, ntd} = Nbn.get_ntd_by_id(SI.ntd_id(), load: [:unis])
      assert length(ntd.unis) == 4
    end

    test "logical edge is quokka-owned, physical NTD/UNIs are NBN's", %{quokka: quokka} do
      # quokka owns the NNI Groups / CVCs (rsp_id stamped)
      {:ok, group} = Nbn.get_nni_group_by_id(SI.group_ids().group_a, actor: quokka)
      assert group.rsp_id == quokka.id

      # NBN owns the NTD and UNIs — not RSP-owned, so no rsp_id field at all
      {:ok, ntd} = Nbn.get_ntd_by_id(SI.ntd_id())
      refute Map.has_key?(ntd, :rsp_id)

      for uni_id <- SI.uni_ids() do
        {:ok, uni} = Nbn.get_uni_by_id(uni_id)
        refute Map.has_key?(uni, :rsp_id)
      end
    end
  end

  describe "lawful intercept — the provisioning choice decides the answer" do
    test "a service on a 10G-group CVC traces to that group's NNIs", %{quokka: quokka} do
      uni = idle_uni()
      cvc = cvc_on(:group_a, quokka)

      _pri = SI.provision_service(uni, cvc, quokka)

      assert intercept(uni.id) == Enum.sort(SI.nni_ids().group_a)
    end

    test "a service on a 100G-group CVC traces to the OTHER group's NNIs", %{quokka: quokka} do
      uni = idle_uni()
      cvc = cvc_on(:group_b, quokka)

      _pri = SI.provision_service(uni, cvc, quokka)

      # Same UNI, different CVC → a different NNI pair. The walk is live.
      assert intercept(uni.id) == Enum.sort(SI.nni_ids().group_b)
    end

    test "an idle UNI with no service traces to nothing" do
      assert intercept(idle_uni().id) == []
    end
  end

  describe "the PRI surfaces the service's geography (#65)" do
    test "a provisioned PRI inherits POI, CSA, LocationPoint and Location", %{quokka: quokka} do
      uni = idle_uni()
      cvc = cvc_on(:group_a, quokka)
      pri = SI.provision_service(uni, cvc, quokka)

      {:ok, pri} =
        Nbn.get_nbn_ethernet_by_id(pri.id,
          load: [:poi, :csa, :location_point, :location],
          actor: quokka
        )

      # Network edge — surfaced from the NNI Group (PRI → AVC → CVC → NNI Group).
      assert pri.poi.id == SI.poi_id()
      assert pri.csa.id == SI.csa_id()
      # Customer premises — surfaced from the NTD (PRI → UNI → NTD).
      assert pri.location_point.id == SI.library_lop_id()
      assert pri.location.id == SI.library_loc_id()
    end
  end

  defp idle_uni do
    {:ok, uni} = Nbn.get_uni_by_id(hd(SI.uni_ids()))
    uni
  end

  defp cvc_on(group, quokka) do
    cvc_id = SI.cvc_ids() |> Map.fetch!(group) |> hd()
    {:ok, cvc} = Nbn.get_cvc_by_id(cvc_id, actor: quokka)
    cvc
  end

  defp intercept(uni_id) do
    {:ok, uni} = Nbn.get_uni_by_id(uni_id, load: [:intercept_nnis])
    uni.intercept_nnis |> Enum.map(& &1.instance_id) |> Enum.sort()
  end
end

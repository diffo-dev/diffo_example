# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.ServiceInitializer do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Seeds the *standing infrastructure* at the Stirling (5STI) point of
  interconnect for the lawful-intercept demo (#60). Nothing here is a customer
  service — provisioning a service onto this infrastructure is the enacted
  journey, see `provision_service/3` (used by the livebook and the test).

  Ownership reflects the real split:

    * **Quokka** (an RSP) owns the *logical* service edge — two NNI Groups
      (one with 2× 10G NNIs, one with 2× 100G NNIs), each carrying two CVCs.
    * **NBN** owns the *physical* access — the on-site NTD at the library and
      its four UNIs (the NTD's four ports), plus all the places. NBN-owned
      records carry no `rsp_id` and are visible to every RSP.

  Built bottom-up using the assigner: a CVC takes an S-VLAN from its NNI Group,
  a UNI takes a port from the NTD; later, provisioning takes a C-VLAN from a
  chosen CVC. Each instance keys on a fixed UUID (the NBN identifier is the
  `name`, not the id) so the seed is idempotent and the demo can address records.
  """
  alias DiffoExample.Nbn
  alias Diffo.Provider.Assignment
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Place

  require Logger

  # PlaceRef role: "this place locates this resource". A module attribute interns
  # the atom at compile time so it round-trips on a cold read (Ash.Type.Atom reads
  # via to_existing_atom) — same footgun the geo seed guards against.
  @locates :locates

  # Stirling Library LocationPoint (seeded in DiffoExample.Nbn.Geo's @locations)
  # that the on-site NTD `:locates`, and the 5STI POI the NNI Groups `:locate` to.
  @library_lop "LOP000620145388"
  @poi "5STI"

  # Fixed UUIDs for every seeded instance — idempotent get-by-id, and stable
  # handles for the test/livebook (exposed via the accessors below).
  @group_a "71854d49-3c77-43cb-921c-bedc4d5c1a15"
  @group_b "5189301a-c6ee-4fbe-8737-7b2350b93270"
  @nni_a1 "a9e6479c-45d7-4c56-8eac-a0f68d463d93"
  @nni_a2 "3a05f80b-9928-4e5f-be2e-b686075203ec"
  @nni_b1 "c40967e5-fd7c-4392-9d32-617f1f6ee2bf"
  @nni_b2 "5011f5c7-acd7-45cf-8687-711f96ec4271"
  @cvc_a1 "d0ebee76-83d4-4322-ada1-bc82fb205714"
  @cvc_a2 "eadbfabd-138c-42b0-b0c5-5e05ad8b0052"
  @cvc_b1 "f93d9a43-f200-4b2a-a5b1-ff71a9349ffa"
  @cvc_b2 "cde7a4ad-ebab-45e8-8d75-b01c603bace5"
  @ntd "96232969-40b6-455d-81dc-d613ca07cb37"
  @uni_1 "b8efb716-6571-447a-a622-7f75a0f0d325"
  @uni_2 "b0a7fa29-4625-4c1d-89eb-2123cbe7fec8"
  @uni_3 "73c931bf-73d7-46e1-9dcf-a8acac7e96cb"
  @uni_4 "cd13d936-5ef6-40b4-be9e-0dc8413ec1d7"

  @doc """
  Seeds the standing 5STI infrastructure, owned by quokka (logical) and NBN
  (physical). Idempotent: a sentinel check on NNI Group A short-circuits a
  re-run. Requires the RSPs and the geo places (5STI, the library LOP) to exist
  first — call after `seed_rsps` and `Geo.seed`.
  """
  def seed do
    case Nbn.get_rsp_by_short_name(:quokka) do
      {:ok, %{} = quokka} ->
        if seeded?(), do: :ok, else: do_seed(quokka)

      _ ->
        Logger.error("ServiceInitializer: quokka RSP not found; skipping service seed")
        :ok
    end
  end

  defp seeded? do
    case Nbn.get_nni_group_by_id(@group_a) do
      {:ok, %{}} -> true
      _ -> false
    end
  end

  defp do_seed(quokka) do
    try do
      # ── Quokka's logical edge at 5STI ──────────────────────────────────────
      # NNI Group A — 2× 10G NNIs
      group_a = build_group!(@group_a, "5STI-NNIG-10G", quokka)
      nni_a1 = build_nni!(@nni_a1, "5STI-ETH-10G-1", 10_000, quokka)
      nni_a2 = build_nni!(@nni_a2, "5STI-ETH-10G-2", 10_000, quokka)
      contain!(group_a, [nni_a1, nni_a2], quokka)

      # NNI Group B — 2× 100G NNIs
      group_b = build_group!(@group_b, "5STI-NNIG-100G", quokka)
      nni_b1 = build_nni!(@nni_b1, "5STI-ETH-100G-1", 100_000, quokka)
      nni_b2 = build_nni!(@nni_b2, "5STI-ETH-100G-2", 100_000, quokka)
      contain!(group_b, [nni_b1, nni_b2], quokka)

      # Two CVCs per group, each taking an S-VLAN from its group (the assigner).
      for {id, group, bw} <- [
            {@cvc_a1, group_a, 1_000},
            {@cvc_a2, group_a, 1_000},
            {@cvc_b1, group_b, 10_000},
            {@cvc_b2, group_b, 10_000}
          ] do
        cvc = build_cvc!(id, bw, quokka)
        assign_svlan!(group, cvc, quokka)
      end

      # ── NBN's physical access at the library ───────────────────────────────
      # The NTD is already on site (no install journey), `:locates` the library
      # LOP, and presents four ports — one per pre-built, idle UNI.
      ntd = build_ntd!()

      for {id, port} <- [{@uni_1, 1}, {@uni_2, 2}, {@uni_3, 3}, {@uni_4, 4}] do
        uni = build_uni!(id, port)
        assign_port!(ntd, uni)
      end

      :ok
    rescue
      e ->
        Logger.error("ServiceInitializer: exception seeding 5STI infrastructure: #{inspect(e)}")
        :ok
    end
  end

  @doc """
  Provisions a customer service: lands the given idle `uni` onto the given `cvc`
  by building a new AVC (taking a C-VLAN from the CVC) and a PRI (NBN Ethernet
  access) that owns the AVC as its `:circuit` and the UNI as its `:port`.

  This is the RSP's order — the choice of CVC is the RSP balancing load across
  its service edge, and it determines which NNI Group (and thus which NNIs) the
  service traverses. Returns the PRI. `actor` is the owning RSP (e.g. quokka).
  """
  def provision_service(uni, cvc, actor) do
    {:ok, avc} = Nbn.build_avc(%{}, actor: actor)

    {:ok, avc} =
      Nbn.define_avc(avc, %{characteristic_value_updates: [avc: [bandwidth_profile: :home_fast]]},
        actor: actor
      )

    {:ok, _cvc} =
      Nbn.assign_cvlan(
        cvc,
        %{assignment: %Assignment{assignee_id: avc.id, alias: :cvc, operation: :auto_assign}},
        actor: actor
      )

    {:ok, pri} = Nbn.build_nbn_ethernet(%{}, actor: actor)

    {:ok, pri} =
      Nbn.relate_nbn_ethernet(
        pri,
        %{
          relationships: [
            %Relationship{id: avc.id, direction: :forward, type: :owns, alias: :circuit},
            %Relationship{id: uni.id, direction: :forward, type: :owns, alias: :port}
          ]
        },
        actor: actor
      )

    pri
  end

  # ── builders ────────────────────────────────────────────────────────────────

  defp build_group!(id, group_name, quokka) do
    {:ok, group} =
      Nbn.build_nni_group(%{id: id, places: [%Place{id: @poi, role: @locates}]}, actor: quokka)

    {:ok, group} =
      Nbn.define_nni_group(
        group,
        %{
          characteristic_value_updates: [
            nni_group: [group_name: group_name, location: "Stirling"],
            svlans: [first: 1, last: 4000, assignable_type: "svlan"]
          ]
        },
        actor: quokka
      )

    group
  end

  defp build_nni!(id, port_id, capacity, quokka) do
    {:ok, nni} = Nbn.build_nni(%{id: id}, actor: quokka)

    {:ok, nni} =
      Nbn.define_nni(
        nni,
        %{characteristic_value_updates: [nni: [port_id: port_id, capacity: capacity]]},
        actor: quokka
      )

    nni
  end

  defp contain!(group, nnis, quokka) do
    relationships =
      Enum.map(nnis, fn nni ->
        %Relationship{id: nni.id, direction: :forward, type: :contains}
      end)

    {:ok, _group} = Nbn.relate_nni_group(group, %{relationships: relationships}, actor: quokka)
    :ok
  end

  defp build_cvc!(id, bandwidth, quokka) do
    {:ok, cvc} = Nbn.build_cvc(%{id: id}, actor: quokka)

    {:ok, cvc} =
      Nbn.define_cvc(
        cvc,
        %{
          characteristic_value_updates: [
            cvc: [bandwidth: bandwidth],
            cvlans: [first: 1, last: 4000, assignable_type: "cvlan"]
          ]
        },
        actor: quokka
      )

    cvc
  end

  defp assign_svlan!(group, cvc, quokka) do
    {:ok, _group} =
      Nbn.assign_svlan(
        group,
        %{
          assignment: %Assignment{assignee_id: cvc.id, alias: :nni_group, operation: :auto_assign}
        },
        actor: quokka
      )

    :ok
  end

  defp build_ntd! do
    {:ok, ntd} = Nbn.build_ntd(%{id: @ntd, places: [%Place{id: @library_lop, role: @locates}]})

    {:ok, ntd} =
      Nbn.define_ntd(ntd, %{
        characteristic_value_updates: [
          ntd: [model: "Sercomm CG4000A", technology: :FTTP],
          ports: [first: 1, last: 4, assignable_type: "port"]
        ]
      })

    ntd
  end

  defp build_uni!(id, port) do
    {:ok, uni} = Nbn.build_uni(%{id: id})

    {:ok, _uni} =
      Nbn.define_uni(uni, %{
        characteristic_value_updates: [
          uni: [port: port, encapsulation: "DSCP Mapped", technology: :FTTP]
        ]
      })

    uni
  end

  defp assign_port!(ntd, uni) do
    {:ok, _ntd} =
      Nbn.assign_port(ntd, %{
        assignment: %Assignment{assignee_id: uni.id, alias: :ntd, operation: :auto_assign}
      })

    :ok
  end

  # ── accessors (stable handles for the test + livebook) ────────────────────────

  @doc "The on-site NTD's id, and the library LocationPoint it `:locates`."
  def ntd_id, do: @ntd
  def library_lop_id, do: @library_lop
  def poi_id, do: @poi

  @doc "The four idle UNI ids (the NTD's four ports)."
  def uni_ids, do: [@uni_1, @uni_2, @uni_3, @uni_4]

  @doc "CVC ids grouped by the NNI Group that carries them."
  def cvc_ids, do: %{group_a: [@cvc_a1, @cvc_a2], group_b: [@cvc_b1, @cvc_b2]}

  @doc "NNI ids grouped by their NNI Group — the expected intercept answers."
  def nni_ids, do: %{group_a: [@nni_a1, @nni_a2], group_b: [@nni_b1, @nni_b2]}

  @doc "NNI Group ids (A = 10G, B = 100G)."
  def group_ids, do: %{group_a: @group_a, group_b: @group_b}
end

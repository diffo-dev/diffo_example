# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.ShowNeo4jTest do
  @moduledoc """
  Tests tagged `:show_neo4j` build a coherent NBN graph in the **real**
  Neo4j database (no sandbox, no rollback) so the result can be inspected
  via the Neo4j browser afterwards.

  Each test prints the Ash-side records and TMF JSON to stdout while it
  runs, and the persisted nodes/relationships remain in Neo4j for further
  exploration. The two tests together build the picture — NniGroup → CVCs
  → AVCs chain (with metrics), and an NTD with assigned UNIs.

  Run with:

      mix test --only show_neo4j

  Excluded from default test runs.
  """
  use ExUnit.Case, async: false

  alias Diffo.Provider.Assignment
  alias Diffo.Provider.Instance.Relationship
  alias DiffoExample.Nbn

  @moduletag :show_neo4j

  test "NniGroup with NNIs, CVCs and an AVC — inheritance + metrics" do
    {:ok, nni_group} = Nbn.build_nni_group(%{})

    {:ok, nni_group} =
      Nbn.define_nni_group(nni_group, %{
        characteristic_value_updates: [
          nni_group: [group_name: "SYD-POI-01", location: "Sydney Olympic Park"],
          svlans: [first: 1, last: 4000, assignable_type: "svlan"]
        ]
      })

    # Two CVCs assigned svlans from this NniGroup
    cvc_ids =
      for bandwidth <- [400, 600] do
        {:ok, cvc} = Nbn.build_cvc(%{})

        {:ok, _} =
          Nbn.define_cvc(cvc, %{
            characteristic_value_updates: [
              cvc: [bandwidth: bandwidth],
              cvlans: [first: 1, last: 4000, assignable_type: "cvlan"]
            ]
          })

        {:ok, _} =
          Nbn.assign_svlan(nni_group, %{
            assignment: %Assignment{
              assignee_id: cvc.id,
              alias: :nni_group,
              operation: :auto_assign
            }
          })

        cvc.id
      end

    # Two NNIs comprised by this NniGroup — realistic capacities so
    # utilization comes out in the 0–1 range
    nni_ids =
      for {port_id, capacity} <- [{"SYD-01-ETH-1", 10000}, {"SYD-01-ETH-2", 10000}] do
        {:ok, nni} = Nbn.build_nni(%{})

        {:ok, _} =
          Nbn.define_nni(nni, %{
            characteristic_value_updates: [
              nni: [port_id: port_id, capacity: capacity]
            ]
          })

        nni.id
      end

    {:ok, _} =
      Nbn.relate_nni_group(nni_group, %{
        relationships:
          Enum.map(nni_ids, fn id ->
            %Relationship{id: id, direction: :forward, type: :contains}
          end)
      })

    # One AVC assigned a cvlan from the first CVC
    cvc1_id = hd(cvc_ids)
    {:ok, cvc1} = Nbn.get_cvc_by_id(cvc1_id)

    {:ok, avc} = Nbn.build_avc(%{})

    {:ok, _} =
      Nbn.define_avc(avc, %{
        characteristic_value_updates: [avc: [bandwidth_profile: :home_fast]]
      })

    {:ok, _} =
      Nbn.assign_cvlan(cvc1, %{
        assignment: %Assignment{
          assignee_id: avc.id,
          alias: :cvc,
          operation: :auto_assign
        }
      })

    # Reload all three with their inheritance calcs / metrics loaded
    {:ok, avc} = Nbn.get_avc_by_id(avc.id, load: [:cvc, :nni_group])
    {:ok, cvc} = Nbn.get_cvc_by_id(cvc1_id, load: [:nni_group])
    {:ok, nni_group} = Nbn.get_nni_group_by_id(nni_group.id, load: [:nnis])

    cvc_metrics =
      DiffoExample.Nbn.CvcMetrics
      |> Ash.Query.filter_input(instance_id: cvc.id)
      |> Ash.Query.load(:value)
      |> Ash.read_one!()

    nni_group_metrics =
      DiffoExample.Nbn.NniGroupMetrics
      |> Ash.Query.filter_input(instance_id: nni_group.id)
      |> Ash.Query.load(:value)
      |> Ash.read_one!()

    IO.puts("\n========== AVC.cvc (single-hop :cvlan) ==========")
    IO.inspect(avc.cvc, label: "avc.cvc")

    IO.puts("\n========== AVC.nni_group (two-hop [:cvlan, :svlan]) ==========")
    IO.inspect(avc.nni_group, label: "avc.nni_group")

    IO.puts("\n========== CVC.nni_group (single-hop :svlan) ==========")
    IO.inspect(cvc.nni_group, label: "cvc.nni_group")

    IO.puts("\n========== CvcMetrics record ==========")
    IO.inspect(cvc_metrics.value, label: "cvc_metrics.value")

    IO.puts("\n========== NniGroupMetrics record ==========")
    IO.inspect(nni_group_metrics.value, label: "nni_group_metrics.value")

    IO.puts("\n========== NniGroup.nnis (brought-up via :contains) ==========")
    IO.inspect(nni_group.nnis, label: "nni_group.nnis")

    IO.puts("\n========== AVC (TMF JSON) ==========")

    avc
    |> Jason.encode!()
    |> Diffo.Util.summarise_dates()
    |> Jason.decode!()
    |> Jason.encode!(pretty: true)
    |> IO.puts()

    IO.puts("\n========== CVC (TMF JSON) ==========")

    cvc
    |> Jason.encode!()
    |> Diffo.Util.summarise_dates()
    |> Jason.decode!()
    |> Jason.encode!(pretty: true)
    |> IO.puts()

    IO.puts("\n========== NniGroup (TMF JSON) ==========")

    nni_group
    |> Jason.encode!()
    |> Diffo.Util.summarise_dates()
    |> Jason.decode!()
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  test "PRI (NbnEthernet access) with full delivery chain — AVC + UNI + CVC + NTD" do
    # CVC + cvlan pool
    {:ok, cvc} = Nbn.build_cvc(%{})

    {:ok, cvc} =
      Nbn.define_cvc(cvc, %{
        characteristic_value_updates: [
          cvc: [svlan: 1, bandwidth: 1000],
          cvlans: [first: 1, last: 100, assignable_type: "cvlan"]
        ]
      })

    # NTD + port pool
    {:ok, ntd} = Nbn.build_ntd(%{})

    {:ok, ntd} =
      Nbn.define_ntd(ntd, %{
        characteristic_value_updates: [
          ntd: [model: "Sercomm CG4000A", technology: :FTTP],
          ports: [first: 1, last: 4, assignable_type: "port"]
        ]
      })

    # AVC + UNI
    {:ok, avc} = Nbn.build_avc(%{})

    {:ok, _} =
      Nbn.define_avc(avc, %{
        characteristic_value_updates: [avc: [bandwidth_profile: :home_fast]]
      })

    {:ok, uni} = Nbn.build_uni(%{})

    {:ok, _} =
      Nbn.define_uni(uni, %{
        characteristic_value_updates: [
          uni: [port: 1, encapsulation: "DSCP Mapped", technology: :FTTP]
        ]
      })

    {:ok, _} =
      Nbn.assign_cvlan(cvc, %{
        assignment: %Assignment{
          assignee_id: avc.id,
          alias: :cvc,
          operation: :auto_assign
        }
      })

    {:ok, _} =
      Nbn.assign_port(ntd, %{
        assignment: %Assignment{
          assignee_id: uni.id,
          alias: :ntd,
          operation: :auto_assign
        }
      })

    # PRI owns AVC (named :circuit from PRI's view) and UNI (named :port).
    {:ok, pri} = Nbn.build_nbn_ethernet(%{})

    {:ok, _} =
      Nbn.relate_nbn_ethernet(pri, %{
        relationships: [
          %Relationship{id: avc.id, direction: :forward, type: :owns, alias: :circuit},
          %Relationship{id: uni.id, direction: :forward, type: :owns, alias: :port}
        ]
      })

    {:ok, pri} = Nbn.get_nbn_ethernet_by_id(pri.id, load: [:avc, :uni, :cvc, :ntd])

    IO.puts("\n========== PRI.avc (single-hop via :avc owns) ==========")
    IO.inspect(pri.avc, label: "pri.avc")

    IO.puts("\n========== PRI.uni (single-hop via :uni owns) ==========")
    IO.inspect(pri.uni, label: "pri.uni")

    IO.puts("\n========== PRI.cvc (two-hop via :avc owns + :cvlan assignment) ==========")
    IO.inspect(pri.cvc, label: "pri.cvc")

    IO.puts("\n========== PRI.ntd (two-hop via :uni owns + :port assignment) ==========")
    IO.inspect(pri.ntd, label: "pri.ntd")

    IO.puts("\n========== PRI (TMF JSON) ==========")

    pri
    |> Jason.encode!()
    |> Diffo.Util.summarise_dates()
    |> Jason.decode!()
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  test "NTD with assigned UNIs" do
    {:ok, ntd} = Nbn.build_ntd(%{})

    {:ok, ntd} =
      Nbn.define_ntd(ntd, %{
        characteristic_value_updates: [
          ntd: [
            model: "Sercomm CG4000A",
            serial_number: "SCOMA1A057A2",
            technology: :FTTP
          ],
          ports: [first: 1, last: 4, assignable_type: "port"]
        ]
      })

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
          assignment: %Assignment{
            assignee_id: uni.id,
            alias: :ntd,
            operation: :auto_assign
          }
        })
    end

    {:ok, ntd} = Nbn.get_ntd_by_id(ntd.id, load: [:unis])

    IO.puts("\n========== NTD.unis (brought-up via :port assignment) ==========")
    IO.inspect(ntd.unis, label: "ntd.unis")

    IO.puts("\n========== NTD (TMF JSON) ==========")

    ntd
    |> Jason.encode!()
    |> Diffo.Util.summarise_dates()
    |> Jason.decode!()
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  test "lawful intercept (#60) — 5STI edge, two provisioned services, divergent NNI paths" do
    alias DiffoExample.Nbn.ServiceInitializer, as: SI

    # Inspection tool: reset the real DB so the browser shows only the #60 graph.
    Bolty.query!(Bolt, "MATCH (n) DETACH DELETE n")

    # quokka (get-or-create — this hits the real DB, no rollback) and the two
    # places the seed relates to, then the standing 5STI infrastructure.
    quokka =
      case Nbn.get_rsp_by_short_name(:quokka) do
        {:ok, %{} = q} ->
          q

        _ ->
          {:ok, q} = Nbn.create_rsp(%{name: "Quokka Connect", short_name: :quokka, id: "0002"})
          {:ok, q} = Nbn.activate_rsp(q)
          q
      end

    {:ok, _poi} =
      Nbn.build_poi(%{
        id: SI.poi_id(),
        name: "Stirling",
        location: %Geo.Point{coordinates: {138.71665, -35.00656}, srid: 4326}
      })

    {:ok, _lop} =
      Nbn.build_location_point(%{
        id: SI.library_lop_id(),
        name: "Stirling Library",
        location: %Geo.Point{coordinates: {138.7186, -35.0030}, srid: 4326}
      })

    :ok = SI.seed()

    # Provision two services — a UNI on the 10G group and another on the 100G
    # group. The RSP's CVC choice decides which NNIs each UNI can traverse.
    [u1, u2 | _] = SI.uni_ids()
    {:ok, uni1} = Nbn.get_uni_by_id(u1)
    {:ok, uni2} = Nbn.get_uni_by_id(u2)
    {:ok, cvc_a} = Nbn.get_cvc_by_id(hd(SI.cvc_ids().group_a), actor: quokka)
    {:ok, cvc_b} = Nbn.get_cvc_by_id(hd(SI.cvc_ids().group_b), actor: quokka)
    SI.provision_service(uni1, cvc_a, quokka)
    SI.provision_service(uni2, cvc_b, quokka)

    {:ok, uni1} = Nbn.get_uni_by_id(u1, load: [:intercept_nnis])
    {:ok, uni2} = Nbn.get_uni_by_id(u2, load: [:intercept_nnis])

    IO.puts("\n========== UNI on 10G group — intercept_nnis (the bearer chain's NNIs) ==========")
    IO.inspect(Enum.map(uni1.intercept_nnis, & &1.port_id), label: "uni1 -> NNIs")

    IO.puts("\n========== UNI on 100G group — intercept_nnis ==========")
    IO.inspect(Enum.map(uni2.intercept_nnis, & &1.port_id), label: "uni2 -> NNIs")

    IO.puts("\n========== Places — NTD :locates LocationPoint, NNI Groups :locate POI ==========")
    {:ok, ntd} = Nbn.get_ntd_by_id(SI.ntd_id(), load: [places: [:place]])
    IO.inspect(Enum.map(ntd.places, &{&1.role, &1.place.id}), label: "NTD places")

    for gid <- Map.values(SI.group_ids()) do
      {:ok, g} = Nbn.get_nni_group_by_id(gid, load: [places: [:place]], actor: quokka)
      IO.inspect(Enum.map(g.places, &{&1.role, &1.place.id}), label: "NNI Group places")
    end

    # The pick is consequential and the traversal is live: each UNI reaches only
    # its own group's two NNIs.
    assert length(uni1.intercept_nnis) == 2
    assert length(uni2.intercept_nnis) == 2
    refute MapSet.equal?(
             MapSet.new(uni1.intercept_nnis, & &1.port_id),
             MapSet.new(uni2.intercept_nnis, & &1.port_id)
           )

    IO.puts("\n========== UNI (TMF JSON) ==========")

    uni1
    |> Jason.encode!()
    |> Diffo.Util.summarise_dates()
    |> Jason.decode!()
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end
end

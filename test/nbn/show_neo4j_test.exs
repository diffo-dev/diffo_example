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
              alias: :svlan,
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
          alias: :cvlan,
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
          assignment: %Assignment{assignee_id: uni.id, operation: :auto_assign}
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
end

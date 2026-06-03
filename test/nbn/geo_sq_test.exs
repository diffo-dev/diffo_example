# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.GeoSqTest do
  @moduledoc """
  Memorialises the geographic service-qualification flow shown in the NBN
  livebook ("Customer locations" / "Service qualification"). If the livebook
  story would break, these tests break first.

  Covers: POI/CSA + customer Location/LocationPoint seeding and pairing, the
  spatial SQ (`st_contains`), the CSA -> POI traversal, the distance to the
  serving POI, and the near-miss distance when SQ finds no CSA.
  """
  use DiffoExample.DataCase, async: true

  import Ash.Expr
  require Ash.Query

  alias DiffoExample.Nbn

  # Stirling Hotel's LocationPoint id (locked in DiffoExample.Nbn.Geo).
  @stirling_hotel_point "LOP000998597184"
  # German Arms, Hahndorf — real FTTP, but outside our coarse Stirling hull.
  @hahndorf %Geo.Point{coordinates: {138.8103, -35.0283}, srid: 4326}

  setup do
    :ok = Nbn.Geo.seed()
    :ok
  end

  describe "seeding" do
    test "POIs and CSAs are paired 1:1" do
      pois = Nbn.list_pois!()
      csas = Nbn.list_csas!()
      assert length(pois) == length(csas)
      assert length(pois) > 0
    end

    test "customer premises and points are seeded and geo-located" do
      assert length(Nbn.list_locations!()) == 5
      # 5 premises points + 2 standalone non-premise points
      assert length(Nbn.list_location_points!()) == 7

      # a premises Location is geo_located by its LocationPoint
      {:ok, loc} =
        Nbn.get_location_by_id("LOC000114541080")
        |> then(fn {:ok, l} -> Ash.load(l, place_refs: [:source_place]) end)

      ref = Enum.find(loc.place_refs, &(&1.role == :geo_locates))
      assert ref
      assert ref.source_place.id == @stirling_hotel_point
    end

    test "standalone non-premise points have no geo_locates ref" do
      {:ok, point} =
        Nbn.get_location_point_by_id("LOP000037364340")
        |> then(fn {:ok, p} -> Ash.load(p, :place_refs) end)

      # nothing targets a non-premise point
      assert point.place_refs == []
    end

    test "seeding is idempotent" do
      before = Nbn.list_location_points!() |> length()
      :ok = Nbn.Geo.seed()
      assert Nbn.list_location_points!() |> length() == before
    end
  end

  describe "service qualification (hit)" do
    test "a customer point resolves to its CSA via st_contains" do
      point = Nbn.get_location_point_by_id!(@stirling_hotel_point)

      csa =
        Nbn.Csa
        |> Ash.Query.filter(st_contains(bounds, ^point.location))
        |> Ash.read!()
        |> List.first()

      assert csa
      assert csa.name == "Stirling"
      assert csa.id == "CSA-5STI"
    end

    test "the qualifying CSA traverses to its POI" do
      point = Nbn.get_location_point_by_id!(@stirling_hotel_point)

      csa =
        Nbn.Csa
        |> Ash.Query.filter(st_contains(bounds, ^point.location))
        |> Ash.read!()
        |> List.first()

      {:ok, csa} = Ash.load(csa, place_refs: [:source_place])
      ref = Enum.find(csa.place_refs, &(&1.role == :interconnects))

      assert ref.source_place.id == "5STI"
    end

    test "distance from the customer point to the serving POI" do
      point = Nbn.get_location_point_by_id!(@stirling_hotel_point)
      poi = Nbn.get_poi_by_id!("5STI")

      [rec] =
        Nbn.LocationPoint
        |> Ash.Query.filter(id == ^point.id)
        |> Ash.Query.calculate(:m, :float, expr(st_distance_in_meters(location, ^poi.location)))
        |> Ash.read!()

      # ~488 m in practice; assert a sane geodesic distance, not a placeholder
      assert is_float(rec.m)
      assert rec.m > 0 and rec.m < 2_000
    end

    test "all three demo pubs qualify to the Stirling CSA" do
      for id <- ["LOP000998597184", "LOP000718290091", "LOP000560061946"] do
        point = Nbn.get_location_point_by_id!(id)

        ids =
          Nbn.Csa
          |> Ash.Query.filter(st_contains(bounds, ^point.location))
          |> Ash.read!()
          |> Enum.map(& &1.id)

        assert "CSA-5STI" in ids
      end
    end
  end

  describe "service qualification (miss)" do
    test "an out-of-coverage point matches no CSA" do
      ids =
        Nbn.Csa
        |> Ash.Query.filter(st_contains(bounds, ^@hahndorf))
        |> Ash.read!()
        |> Enum.map(& &1.id)

      assert ids == []
    end

    test "near-miss distance to the nearest CSA edge" do
      nearest_pois =
        Nbn.Poi
        |> Ash.Query.calculate(:m, :float, expr(st_distance_in_meters(location, ^@hahndorf)))
        |> Ash.read!()
        |> Enum.sort_by(& &1.m)
        |> Enum.take(6)
        |> Enum.map(& &1.id)

      best =
        Nbn.Csa
        |> Ash.Query.filter(id in ^Enum.map(nearest_pois, &("CSA-" <> &1)))
        |> Ash.Query.calculate(:edge_m, :float, expr(st_distance_in_meters(bounds, ^@hahndorf)))
        |> Ash.read!()
        |> Enum.sort_by(& &1.edge_m)
        |> List.first()

      # st_distance works point-to-polygon — Hahndorf is ~3 km from the
      # Stirling CSA edge (≈ the real Hahndorf–Verdun distance).
      assert best.name == "Stirling"
      assert best.edge_m > 2_000 and best.edge_m < 4_000
    end
  end
end

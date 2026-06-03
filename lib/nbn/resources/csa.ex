# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Csa do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Csa - NBN Connectivity Serving Area

  A CSA is the hinterland served by a POI — the area of premises whose traffic
  backhauls to that interconnect. Each CSA has a boundary (a polygon) and is
  paired 1:1 with its POI via a `PlaceRef` (POI -> CSA).

  A TMF675 GeographicLocation (a `bounds` polygon), keyed by the NBN POI Ref it
  is served by (e.g. "5EDW" Edwardstown). CVCs serve a CSA (#26).

  The boundary is a coarse convex hull derived (and simplified) from NBN's
  published fixed-line coverage dataset — see `DiffoExample.Nbn.Geo` for the
  source and attribution.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicLocation

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicLocation],
    domain: Nbn

  resource do
    description "An NBN Connectivity Serving Area (CSA)"
    plural_name :csas
  end

  actions do
    create :build do
      description "creates a CSA with a boundary"
      accept [:id, :href, :name, :bounds]
      change set_attribute(:type, :GeographicLocation)
      upsert? true
    end

    update :define do
      description "defines fields on a CSA"
      accept [:name, :href, :bounds]
    end
  end
end

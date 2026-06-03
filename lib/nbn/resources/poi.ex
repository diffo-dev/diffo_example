# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Poi do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Poi - NBN Point of Interconnect

  A POI is the physical interconnect site where RSPs hand traffic to/from the
  NBN. Each POI has a fixed location (a point) and is paired 1:1 with the CSA
  (Connectivity Serving Area) it interconnects, via a `PlaceRef` (POI -> CSA).

  A TMF675 GeographicLocation (a `location` point), keyed by the NBN POI Ref
  (e.g. "5EDW" Edwardstown). NNI Groups are at a POI (#26).
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicLocation

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicLocation],
    domain: Nbn

  resource do
    description "An NBN Point of Interconnect (POI)"
    plural_name :pois
  end

  actions do
    create :build do
      description "creates a POI at a location"
      accept [:id, :href, :name, :location]
      change set_attribute(:type, :GeographicLocation)
      upsert? true
    end

    update :define do
      description "defines fields on a POI"
      accept [:name, :href, :location]
    end
  end
end

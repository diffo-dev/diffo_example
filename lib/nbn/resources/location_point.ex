# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.LocationPoint do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  LocationPoint - the lat/long where a service is delivered.

  The point is the anchor: it is always present and is what service
  qualification runs against (which CSA's bounds contain it). A postal
  GeographicAddress is a separate, optional concern — non-premise NBN
  locations (a street cabinet that needs comms but has no postal address)
  legitimately have only a point.

  A TMF675 GeographicLocation (a `location` point), in the NBN domain so it
  can carry consumer-specific richness later.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicLocation

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicLocation],
    domain: Nbn

  resource do
    description "A LocationPoint — the lat/long where a service is delivered"
    plural_name :location_points
  end

  actions do
    create :build do
      description "creates a location point"
      accept [:id, :href, :name, :location]
      change set_attribute(:type, :GeographicLocation)
      upsert? true
    end

    update :define do
      description "defines fields on a location point"
      accept [:name, :href, :location]
    end
  end
end

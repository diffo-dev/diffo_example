# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Location do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Location - a premises with a street address.

  The postal/street identity of a place (a TMF675 GeographicAddress). The
  property name is carried in `name` (e.g. "Stirling Hotel"); the street
  parts are the address attributes. A `LocationPoint` (lat/long) geo-locates
  a Location via a PlaceRef (role `:geo_locates`) — the point is what service
  qualification runs against, the Location is the human-readable premises.

  In the NBN domain so it can carry consumer-specific richness later.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicAddress

  alias DiffoExample.Nbn

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicAddress],
    domain: Nbn

  resource do
    description "A Location — a premises with a street address"
    plural_name :locations
  end

  actions do
    create :build do
      description "creates a location (premises address)"
      accept [:id, :href, :name, :street_nr, :street_name, :locality, :state_or_province, :country, :postcode]
      change set_attribute(:type, :GeographicAddress)
      upsert? true
    end

    update :define do
      description "defines fields on a location"
      accept [:name, :href, :street_nr, :street_name, :locality, :state_or_province, :country, :postcode]
    end
  end
end

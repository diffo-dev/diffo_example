# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Initializer do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Initializes the NBN domain on application startup:
  - seeds RSP records in historical EPID sequence
  - seeds POI and CSA places, paired POI -> CSA
  """

  alias DiffoExample.Nbn
  alias DiffoExample.Nbn.Geo

  @rsps [
    %{name: "Wedge-tail Telecom", short_name: :wedgetail, id: "0001"},
    %{name: "Quokka Connect", short_name: :quokka, id: "0002"},
    %{name: "Ibis Telecom", short_name: :ibis, id: "0003"},
    %{name: "Taipan Group", short_name: :taipan, id: "0004"},
    %{name: "Echidna Networks", short_name: :echidna, id: "0005"},
    %{name: "Dugong Digital", short_name: :dugong, id: "0006"}
    # %{name: "Lyrebird",           short_name: :lyrebird,  id: "0007"}
  ]

  def init do
    seed_rsps()
    Geo.seed()
  end

  defp seed_rsps do
    Enum.each(@rsps, fn attrs ->
      try do
        case Nbn.get_rsp_by_epid(attrs.id) do
          {:ok, nil} -> seed_rsp(attrs)
          {:ok, _} -> :ok
          {:error, _} -> seed_rsp(attrs)
        end
      rescue
        e ->
          require Logger
          Logger.error("Exception seeding RSP #{attrs.id}: #{inspect(e)}")
      end
    end)
  end

  defp seed_rsp(attrs) do
    {:ok, rsp} = Nbn.create_rsp(attrs)
    {:ok, _} = Nbn.activate_rsp(rsp)
  end
end

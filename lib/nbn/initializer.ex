# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Initializer do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Initializes the NBN domain on application startup:
  - upserts all resource specifications into the catalog
  - seeds RSP records in historical EPID sequence
  """

  alias Diffo.Provider.Instance.Specification
  alias DiffoExample.Nbn

  @rsps [
    %{name: "Wedge-tail Telecom", short_name: :wedgetail, epid: "0001"},
    %{name: "Quokka Connect",     short_name: :quokka,    epid: "0002"},
    %{name: "Ibis Telecom",       short_name: :ibis,      epid: "0003"},
    %{name: "Taipan Group",       short_name: :taipan,    epid: "0004"},
    %{name: "Echidna Networks",   short_name: :echidna,   epid: "0005"},
    %{name: "Dugong Digital",     short_name: :dugong,    epid: "0006"},
    %{name: "Lyrebird",           short_name: :lyrebird,  epid: "0007"}
  ]

  def init do
    Nbn
    |> Ash.Domain.Info.resources()
    |> Enum.each(fn module ->
      try do
        Specification.upsert_specification(module)
      rescue
        _ -> :ok
      end
    end)

    seed_rsps()
  end

  defp seed_rsps do
    Enum.each(@rsps, fn attrs ->
      try do
        case Nbn.get_rsp_by_epid(attrs.epid) do
          {:ok, nil} -> seed_rsp(attrs)
          {:ok, _} -> :ok
          {:error, _} -> seed_rsp(attrs)
        end
      rescue
        e -> require Logger; Logger.error("Exception seeding RSP #{attrs.epid}: #{inspect(e)}")
      end
    end)
  end

  defp seed_rsp(attrs) do
    {:ok, rsp} = Nbn.create_rsp(attrs)
    {:ok, _} = Nbn.activate_rsp(rsp)
  end
end

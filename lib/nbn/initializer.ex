# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Initializer do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Initializes the NBN domain's specifications in the catalog on application startup,
  so the catalog is populated before any instances are built.
  """

  alias Diffo.Provider.Instance.Specification

  def init do
    DiffoExample.Nbn
    |> Ash.Domain.Info.resources()
    |> Enum.each(fn module ->
      try do
        Specification.upsert_specification(module)
      rescue
        _ -> :ok
      end
    end)
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Catalog do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Catalog - the NBN resource and service catalog.
  """

  def list do
    Diffo.Provider.list_specifications!()
    |> Enum.map(fn spec ->
      Jason.OrderedObject.new(
        id: spec.id,
        href: spec.href,
        name: spec.name,
        version: spec.version,
        description: spec.description,
        category: spec.category
      )
    end)
  end
end

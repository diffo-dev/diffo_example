# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.ShelfValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  ShelfValue - AshTyped Struct for Shelf Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:name, :family, :model, :technology]
    compact(true)
  end

  outstanding do
    expect [:name]
  end

  typed_struct do
    field :name, :string, description: "the shelf name"

    field :family, :atom, description: "the shelf family name"

    field :model, :string, description: "the shelf model name"

    field :technology, :atom, description: "the shelf technology"
  end
end

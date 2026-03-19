# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.AvcValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  AvcValue - AshTyped Struct for AVC Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:cir, :pir]
    compact(true)
  end

  outstanding do
    expect [:cir, :pir]
  end

  typed_struct do
    field :cir, :integer, description: "Committed Information Rate in Mbps"

    field :pir, :integer, description: "Peak Information Rate in Mbps"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.NtdValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NtdValue - AshTyped Struct for NTD Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.Technology

  jason do
    pick [:model, :serial_number, :technology]
    compact(true)
  end

  outstanding do
    expect [:model, :serial_number]
  end

  typed_struct do
    field :model, :string, description: "the NTD device model"

    field :serial_number, :string, description: "the NTD serial number"

    field :technology, Technology,
      description: "the access technology type",
      default: Technology.default()
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

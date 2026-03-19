# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.CvcValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  CvcValue - AshTyped Struct for Connectivity Virtual Circuit Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:cvc_id, :bandwidth]
    compact(true)
  end

  outstanding do
    expect [:cvc_id, :bandwidth]
  end

  typed_struct do
    field :cvc_id, :string, description: "the unique CVC identifier"

    field :bandwidth, :integer, description: "total CVC bandwidth in Mbps"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

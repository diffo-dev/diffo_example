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
    pick [:svlan, :bandwidth]
    compact(true)
  end

  outstanding do
    expect [:svlan, :bandwidth]
  end

  typed_struct do
    field :svlan, :integer,
      constraints: [min: 0, max: 4000],
      description: "the svlan of the CVC, assigned by the related NNI Group"

    field :bandwidth, :integer,
      constraints: [min: 0, max: 10000],
      description: "total CVC bandwidth in Mbps"
  end
end

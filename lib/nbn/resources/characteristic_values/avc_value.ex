# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.AvcValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  AvcValue - AshTyped Struct for AVC Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.BandwidthProfile

  jason do
    pick [:cvlan, :bandwidth_profile]
    compact(true)
  end

  outstanding do
    expect [:cvlan, :bandwidth_profile]
  end

  typed_struct do
    field :cvlan, :integer,
      constraints: [min: 0, max: 4000],
      description: "the cvlan of the AVC, assigned by the related CVC"

    field :bandwidth_profile, BandwidthProfile, description: "the bandwidth profile of the AVC"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

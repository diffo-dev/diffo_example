# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.Constraints do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Constraints - AshTyped Struct for Constraints Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:max_latency, :min_profile]
    compact(true)
    rename max_latency: "maxLatency", min_profile: "minProfile"
  end

  outstanding do
    expect [:max_latency, :min_profile]
  end

  typed_struct do
    field :max_latency, :integer,
      constraints: [min: 0, max: 47],
      description: "the maximum latency in ms"

    field :min_profile, :struct,
      constraints: [instance_of: BandwidthProfile],
      description: "the circuit bandwidth profile"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

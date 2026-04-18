# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.PriValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  NbnEthernetValue - AshTyped Struct for NBN Ethernet Access Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  alias DiffoExample.Nbn.Technology
  alias DiffoExample.Nbn.BandwidthProfile
  alias DiffoExample.Nbn.Speeds

  jason do
    pick [:avcid, :uniid, :technology, :bandwidth_profile, :speeds]
    compact(true)
    rename avcid: "AVCID", uniid: "UNIID", bandwidth_profile: "bandwidthProfile"
  end

  outstanding do
    expect [:avcid, :uniid, :technology, :bandwidth_profile, :speeds]
  end

  typed_struct do
    field :avcid, :string, description: "the avcid from the owned Avc Resource"

    field :uniid, :string, description: "the uniid from the owned Uni Resource"

    field :technology, Technology, description: "the technology type"

    field :bandwidth_profile, BandwidthProfile, description: "the bandwidth profile"

    field :speeds, Speeds, description: "the downstream and upstream speeds in Mbps"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule DiffoExample.Nbn.Speeds do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Speeds type for NBN domain
  """

  require Ash.Type.NewType

  use Ash.Type.NewType,
    subtype_of: :tuple,
    constraints: [
      fields: [downstream: [type: :integer], upstream: [type: :integer]]
    ]

  def speeds do
    [
      {12, 1},
      {25, 5},
      {25, 10},
      {50, 20},
      {100, 40},
      {250, 100},
      {500, 200},
      {1000, 400},
      # :home_fast
      {500, 50},
      # :home_superfast
      {750, 50},
      # :home_ultrafast
      {1000, 100},
      # :home_hyperfast
      {2000, 100},
      {2000, 200},
      # :wireless_plus, :wireless_fast, :wireless_superfast
      {100, 20},
      {250, 20},
      {400, 40}
    ]
  end

  @impl true
  def cast_input(nil, _constraints), do: {:ok, nil}

  def cast_input(value, _constraints) when is_tuple(value) do
    if value in speeds() do
      {:ok, value}
    else
      {:error, "invalid downstream and upstream speed combination"}
    end
  end

  def cast_input({_value, _constraints}), do: {:error, "value must be a tuple"}

  defimpl Jason.Encoder do
    def encode(speeds, _opts) do
      Jason.OrderedObject.new(
        downstream: speeds.downstream,
        upstream: speeds.upstream,
        units: "Mbps"
      )
      |> Jason.encode!()
    end
  end
end

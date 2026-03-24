# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Util do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Util - various utilities for NBN domain

  """

  @doc """
  Generates a new random NBN identifier with the prefix

  ## Examples
    iex> identifier = DiffoExample.Nbn.Util.identifier("AVC")
    iex> DiffoExample.Nbn.Util.identifier?(identifier)
    true

  """
  def identifier(prefix) when is_binary(prefix) and byte_size(prefix) == 3 do
    prefix <>
      (:rand.uniform(000_999_999_999)
       |> Integer.to_string()
       |> String.pad_leading(12, "0"))
  end

  @doc """
  Returns whether the identifier is a valid NBN identifier

  ## Examples
    iex> DiffoExample.Nbn.Util.identifier?("AVC120123456789")
    true
    iex> DiffoExample.Nbn.Util.identifier?("avc120123456789")
    false
  """
  def identifier?(identifier) when is_binary(identifier) do
    Regex.match?(~r/[A-Z]{3}\d{12}/, identifier)
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Access.ActionHelper do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  ActionHelper - helping with actions
  """

  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias DiffoExample.Access

  @doc """
  build before_action helper, injects instance dsl configuration into the changeset
  """
  def build_before(changeset) do
    changeset
    |> Specification.set_specified_by_argument()
    |> Feature.set_features_argument()
    |> Characteristic.set_characteristics_argument()
  end

  @doc """
  build after_action helper, relates TMF entities to the new instance
  """
  def build_after(changeset, result, get_by_id_method) do
    with {:ok, result} <- Specification.relate_instance(result, changeset),
         {:ok, result} <- Relationship.relate_instance(result, changeset),
         {:ok, result} <- Feature.relate_instance(result, changeset),
         {:ok, result} <- Characteristic.relate_instance(result, changeset),
         {:ok, result} <- Place.relate_instance(result, changeset),
         {:ok, result} <- Party.relate_instance(result, changeset),
         {:ok, result} <- apply(Access, get_by_id_method, [result.id]),
         do: {:ok, result}
  end
end

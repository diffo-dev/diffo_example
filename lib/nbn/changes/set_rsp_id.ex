# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Changes.SetRspId do
  use Ash.Resource.Change

  def change(changeset, _opts, %{actor: %{id: id}}) do
    Ash.Changeset.force_change_attribute(changeset, :rsp_id, id)
  end

  def change(changeset, _opts, _context), do: changeset
end

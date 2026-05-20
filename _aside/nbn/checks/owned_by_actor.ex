# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Checks.OwnedByActor do
  @moduledoc false
  use Ash.Policy.FilterCheck

  @impl true
  def describe(_opts), do: "actor owns resource (rsp_id matches actor id)"

  @impl true
  def filter(actor, _context, _opts) do
    case actor do
      %{id: id} -> [rsp_id: id]
      _ -> false
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.Nbn.Checks.NoActor do
  @moduledoc false
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts), do: "no actor present (internal Perentie call)"

  @impl true
  def match?(nil, _context, _opts), do: true
  def match?(_actor, _context, _opts), do: false
end

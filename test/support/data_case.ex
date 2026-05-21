# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExample.DataCase do
  @moduledoc """
  ExUnit case template that opens an AshNeo4j sandbox checkout per test and
  rolls it back on exit.

      use DiffoExample.DataCase

  is equivalent to:

      use ExUnit.Case, async: true

      setup do
        AshNeo4j.Sandbox.checkout()
        on_exit(&AshNeo4j.Sandbox.rollback/0)
      end
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      setup do
        AshNeo4j.Sandbox.checkout()
        on_exit(&AshNeo4j.Sandbox.rollback/0)
      end
    end
  end
end

# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo-example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule DiffoExampleTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest DiffoExample.Access.Util
  #doctest DiffoExample.Nbn.Util
  #doctest DiffoExample.Nbn.Speeds
end

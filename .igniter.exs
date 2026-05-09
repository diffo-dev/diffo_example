# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

# This is a configuration file for igniter.
# For option documentation, see https://hexdocs.pm/igniter/Igniter.Project.IgniterConfig.html
# To keep it up to date, use `mix igniter.setup`
[
  module_location: :outside_matching_folder,
  extensions: [],
  deps_location: :last_list_literal,
  source_folders: ["lib", "test/support"],
  dont_move_files: [~r"lib/mix"]
]

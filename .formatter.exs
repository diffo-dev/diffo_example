# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

# Used by "mix format"
locals_without_parens = [
  tool: 3,
  tool: 4
]

[
  plugins: [Spark.Formatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [
    :diffo,
    :ash,
    :ash_ai,
    :ash_state_machine,
    :ash_neo4j,
    :ash_jason,
    :ash_outstanding,
    :ash_json_api,
    :plug
  ],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]

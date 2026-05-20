# SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>
#
# SPDX-License-Identifier: MIT

import Config

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :resource,
        :code_interface,
        :specification,
        :features,
        :characteristics,
        :neo4j,
        :jason,
        :json_api,
        :outstanding,
        :actions,
        :state_machine,
        :attributes,
        :relationships,
        :identities,
        :aggregates,
        :calculations,
        :preparations
      ]
    ],
    "Ash.TypedStruct": [
      section_order: [
        :jason,
        :outstanding,
        :fields
      ]
    ]
  ]

config :diffo, ash_domains: [Diffo.Provider]
config :diffo_example, ash_domains: [DiffoExample.Access]
import_config "#{config_env()}.exs"

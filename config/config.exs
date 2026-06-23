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

# diffo 0.9.0: the edge-managing provider actions manage relationships or run
# non-atomic validations, so atomic-by-default must be disabled for the consumer.
# diffo's resources recompile under this config; without it those actions raise
# "must be performed atomically". See diffo CHANGELOG v0.9.0.
config :ash, :require_atomic_by_default?, false

config :diffo, ash_domains: [Diffo.Provider]
config :diffo_example, ash_domains: [DiffoExample.Access, DiffoExample.Nbn]
import_config "#{config_env()}.exs"

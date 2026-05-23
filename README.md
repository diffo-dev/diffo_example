<!--
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Diffo Example

[![Module Version](https://img.shields.io/hexpm/v/diffo)](https://hex.pm/packages/diffo_example)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen)](https://hexdocs.pm/diffo_example/)
[![License](https://img.shields.io/hexpm/l/diffo)](https://github.com/diffo-dev/diffo_example/blob/master/LICENSES/MIT.md)
[![REUSE status](https://api.reuse.software/badge/github.com/diffo-dev/diffo_example)](https://api.reuse.software/info/github.com/diffo-dev/diffo_example)

[Diffo](https://github.com/diffo-dev/diffo) is a Telecommunications Management Forum (TMF) Service and Resource Manager, built for autonomous networks.

This repo contains two independent example domains, plus an orientation to the underlying Diffo Provider primitives. Read in this order:

1. **[The Access Domain](documentation/domains/access.md)** — the warm-up. A single fictional telco delivering DSL service over copper to its own customers. Five resources, one service, a small state machine. Walks the pattern end-to-end.
2. **[The Provider Domain](documentation/domains/provider.md)** — lifts the lid on the primitives Access has been using the whole time (Specification, Instance, typed Characteristics, Pools, Assignments, Relationships, Place, Party, state machine, the TMF JSON encoder).
3. **[The NBN Domain](documentation/domains/nbn.md)** — the deeper case. A fictional wholesale broadband network shared by many Retail Service Providers. Adds multi-tenancy via Ash Policy, a longer delivery chain, and the named-vs-metrics characteristic pattern with cross-resource inheritance.

Each domain ships with a runnable livebook.

## Access Livebook

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo-dev%2Fdiffo_example%2Fblob%2Fmain%2Fdocumentation%2Fdomains%2Fdiffo_example_access.livemd)

End-to-end scenario through the code-interface — exchange shelf with line cards, a customer access path through copper, qualify and design a DSL service for the subscriber, then read the inheritance chain.

## NBN Livebook

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo-dev%2Fdiffo_example%2Fblob%2Fmain%2Fdocumentation%2Fdomains%2Fdiffo_example_nbn.livemd)

The wholesale story — pick an RSP, build the shareable NNI Group / CVC, provision a subscriber's NBN Ethernet access end-to-end, then read the full delivery chain through inheritance and the live metrics on each resource.

## API reference (auto-generated)

- [Access Domain API](documentation/domains/_access_api.md) — every code-interface function on `DiffoExample.Access`.
- [NBN Domain API](documentation/domains/_nbn_api.md) — every code-interface function on `DiffoExample.Nbn`.

Both are regenerated from the domain DSL with `mix gen.api_docs`.

## Installation

The package can be installed by adding `diffo_example` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diffo_example, "~> 0.2"}
  ]
end
```

You need [Neo4j](https://github.com/neo4j/neo4j) available. We recommend the Neo4j Community 5 latest, available at the [Neo4j Deployment Centre](https://neo4j.com/deployment-center/) which can be installed locally. You can also configure connection to a cloud-based database service such as [Neo4j AuraDB](https://neo4j.com/product/auradb/).

## Contributions

Contributions are welcome, please start with an [issue](https://github.com/diffo-dev/diffo_example/issues).

## Acknowledgements

Thanks to my colleagues in the Telco industry.

Thanks to the vibrant Elixir and Ash communities, and in particular the [Ash Core](https://github.com/ash-project) for [ash](https://github.com/ash-project/ash) 🚀

Thanks to [Florin Patrascu](https://github.com/florinpatrascu) for [bolt_sips](https://github.com/florinpatrascu/bolt_sips) and [Luis Sagastume](https://github.com/sagastume) for [boltx](https://github.com/sagastume/boltx), both forerunners of [bolty](https://github.com/diffo-dev/bolty) — the Bolt driver for Neo4j.

Thanks to the [Neo4j Core](https://github.com/neo4j) for [neo4j](https://github.com/neo4j/neo4j) and pioneering work on graph databases.

## Links

- [Diffo TMF Service and Resource Manager](https://github.com/diffo-dev/diffo)
- [Diffo.dev](https://www.diffo.dev)
- [Ash Neo4j Datalayer](https://github.com/diffo-dev/ash_neo4j)
- [bolty](https://github.com/diffo-dev/bolty)
- [Neo4j Deployment Centre](https://neo4j.com/deployment-center/)
- [Ash Outstanding Extension](https://github.com/diffo-dev/ash_outstanding)
- [Outstanding Elixir Protocol](https://github.com/diffo-dev/outstanding)
- [TMF](https://www.tmforum.org)

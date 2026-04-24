<!--
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Diffo Example

[![Module Version](https://img.shields.io/hexpm/v/diffo)](https://hex.pm/packages/diffo_example)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen)](https://hexdocs.pm/diffo_example/)
[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo-dev%2Fdiffo_example%2Fblob%2Fmain%2Fdiffo_example.livemd)
[![License](https://img.shields.io/hexpm/l/diffo)](https://github.com/diffo-dev/diffo_example/blob/master/LICENSES/MIT.md)
[![REUSE status](https://api.reuse.software/badge/github.com/diffo-dev/diffo_example)](https://api.reuse.software/info/github.com/diffo-dev/diffo_example)

This repo contains Diffo Examples.

[Diffo](https://github.com/diffo-dev/diffo) is a Telecommunications Management Forum (TMF) Service and Resource Manager, built for autonomous networks.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `diffo_example` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diffo_example, "~> 0.0.2"}
  ]
end
```

You need [Neo4j](https://github.com/neo4j/neo4j) available. We recommend the Neo4j Community 5 latest, available at [Neo4j Deploymnent Centre](https://neo4j.com/deployment-center/) which can be installed locally. You can also configure connection to a cloud based database service such as [Neo4j AuraDB](https://neo4j.com/product/auradb/).

## Tutorial

Click the **Run in Livebook** badge above to open the interactive tutorial, or find it at [diffo_example.livemd](diffo_example.livemd).

The diffo_example livebook walks through provisioning a complete NBN Ethernet access circuit — NTD, UNI, AVC, CVC, NNI Group, and NNI — showing how the `mine` actions propagate technology, speeds, CVLAN, and port assignments up the resource hierarchy.


## Contributions

Contributions are welcome, please start with an [issue](https://github.com/diffo-dev/diffo_example/issues)

## Acknowledgements

Thanks to my colleagues in the Telco industry.

Thanks to the vibrant Elixir and Ash communities, and in particular the [Ash Core](https://github.com/ash-project) for [ash](https://github.com/ash-project/ash) 🚀

Thanks to [Florin Patrascu](https://github.com/florinpatrascu) for [bolt_sips](https://github.com/florinpatrascu/bolt_sips) and[Luis Sagastume](https://github.com/sagastume) for [boltx](https://github.com/sagastume/boltx), both forerunners of [bolty](https://github.com/diffo-dev/bolty) the bolt driver for neo4j.

Thanks to the [Neo4j Core](https://github.com/neo4j) for [neo4j](https://github.com/neo4j/neo4j) and pioneering work on graph databases.

## Links

[Diffo TMF Service and Resource Manager](https://github.com/diffo-dev/diffo)
[Diffo.dev](https://www.diffo.dev)
[Ash Neo4j Datalayer](https://github.com/diffo-dev/ash_neo4j)
[bolty](https://github.com/diffo-dev/bolty)
[Neo4j Deployment Centre](https://neo4j.com/deployment-center/)
[Ash Outstanding Extension](https://github.com/diffo-dev/ash_outstanding)
[Outstanding Elixir Protocol](https://github.com/diffo-dev/outstanding)
[TMF](https://www.tmforum.org)


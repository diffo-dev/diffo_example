<!-- 
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.2.1](https://github.com/diffo-dev/diffo/compare/v0.2.0..v0.2.1) (2026-05-07)

### Maintenance:
* updated to diffo 0.2.1

### Features:
* using transactions and test sandbox
* using improved provider DSL

## [v0.2.0](https://github.com/diffo-dev/diffo/compare/v0.0.4..v0.2.0) (2026-04-26)

### Maintenance:
* updated to diffo 0.2.0

### Features:
* new NBN domain modelling NBN Ethernet access and constituent resources (UNI, AVC, NTD, CVC, NNI Group, NNI)
* JSON API via AshJsonApi and Plug.Cowboy
* RSP resource with AshStateMachine lifecycle (inactive/active/suspended) and Ash Policy authorisation
* RSP multi-tenancy: SetRspId change, OwnedByActor and NoActor policy checks, RspOwnership macro shared across RSP-owned resources
* NTD and UNI modelled as NBN-owned infrastructure — readable by any RSP, mutable only by internal calls
* Interactive NBN livebook with Kino RSP selector and actor-scoped provisioning flow
* NBN domain documentation including Perentie ecosystem narrative

## [v0.0.4](https://github.com/diffo-dev/diffo/compare/v0.0.3..v0.0.4) (2026-03-19)

### Fixes:
* fixed relationship enrichment inconsistent across neo4j versions

## [v0.0.3](https://github.com/diffo-dev/diffo/compare/v0.0.2..v0.0.3) (2026-03-13)

### Maintenance:
* updated to diffo 0.1.4, using ash_neo4j 0.2.13 using fork bolty 0.0.7 rather than boltx 0.0.6

## [v0.0.2](https://github.com/diffo-dev/diffo/compare/v0.0.1..v0.0.2) (2025-12-01)

### Maintenance:
* updated to diffo 0.1.3

## [v0.0.1](https://github.com/diffo-dev/diffo/compare/v0.0.1..v0.0.1) (2025-10-20)

### Features:
* initial version


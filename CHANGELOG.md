<!-- 
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.5.0](https://github.com/diffo-dev/diffo_example/compare/v0.4.0..v0.5.0) (2026-06-24)

### Maintenance:
* bumped to diffo 0.9.0 — target Neo4j is now **2026.05** (Cypher 25 / BOLT 6.0); adds the mandatory `config :ash, :require_atomic_by_default?, false` (the 0.8.x→0.9.0 step), updates both livebooks, and adds a `docker-compose.yml` for a local Neo4j 2026.05. All tests pass with no Access/NBN domain logic changes (#69)
* dropped two unused `require Ash.Query` and applied pending `mix format` normalizations

## [v0.4.0](https://github.com/diffo-dev/diffo_example/compare/v0.3.0..v0.4.0) (2026-06-04)

### Features:
* the PRI surfaces its full geography via `inherited_place` — the POI and its CSA (from the NNI Group) and the customer's LocationPoint and Location (from the NTD) — using diffo 0.8.0's unified `via:` traversal grammar, now extended to places ([diffo#226](https://github.com/diffo-dev/diffo/issues/226)). The NNI Group and NTD carry both places directly, pending place→place traversal ([diffo#227](https://github.com/diffo-dev/diffo/issues/227)) (#65)

### Maintenance:
* bumped to diffo 0.8.0 (#65)

## [v0.3.0](https://github.com/diffo-dev/diffo_example/compare/v0.2.3..v0.3.0) (2026-06-04)

### Features:
* spatial service qualification — NBN CSA and POI places for South Australia, a LocationPoint (the SQ anchor) and Location premises, with `st_contains` point-in-CSA qualification and CSA→POI traversal; SQ livebook section + tests (#26)
* lawful-intercept traversal showcase — `Uni.intercept_nnis`, one 5-hop `via:` declaration (UNI→PRI→AVC→CVC→NNI Group→NNIs) demonstrating the unified traversal grammar; a standing 5STI service seed (quokka-owned NNI Groups/CVCs, NBN-owned NTD + four idle UNIs) with `:locates` place refs and a `provision_service` helper; livebook section + path-selective tests (#60)

### Maintenance:
* migrated to diffo 0.7.0 — adopted the unified `inherited_characteristic` traversal grammar and the Service/Resource cascade, Phases 1–3 (#59)
* reconciled the NBN MCP tool surface with the domain code interface (#58)

## [v0.2.3](https://github.com/diffo-dev/diffo/compare/v0.2.2..v0.2.3) (2026-05-22)

### Maintenance:
* updated to diffo 0.4.1 (issue #48)
* refreshed agent guidance via `mix usage_rules.sync`

### Refactors:
* adopted upstream `Diffo.Provider.Changes.{Define,Relate,Assign}` across 11 instance resources; deleted the local `DiffoExample.Changes.*` trio now that the same modules ship in diffo proper ([diffo#170](https://github.com/diffo-dev/diffo/pull/170))
* slimmed 16 `BaseCharacteristic`-derived resources by relying on the auto-generated `:create`/`:update` actions ([diffo#171](https://github.com/diffo-dev/diffo/pull/171)) — ~360 lines removed; custom `:update` retained on `cable`, `path`, `circuit`, `constraints` where unit/bandwidth-profile composition is needed
* `Cable.relate` inline `after_action` (which referenced an unaliased `Relationship` module) folded into `change Diffo.Provider.Changes.Relate`

### Resolved workarounds:
* `DslAccess.qualify_result` now transitions to `:feasibilityChecked` — restores correct TMF form following [diffo#168](https://github.com/diffo-dev/diffo/pull/168) broadening the Assigner lifecycle gate to include `:feasibilityChecked`
* `Util.summarise_characteristics/2` no longer called from tests — typed characteristic + pool records now surface in TMF JSON by default ([diffo#169](https://github.com/diffo-dev/diffo/pull/169)). The projection function is retained in [lib/diffo_example/util.ex](lib/diffo_example/util.ex) for future projection demonstrations. Expected JSON strings updated across `cable`, `card`, `cable`, `path`, `shelf`, `dsl_access`, `nbn_ethernet` tests to reflect the real typed/pool surfacing

### Features:
* NBN — AVC, CVC, NniGroup characteristic inheritance and metrics (issue #49):
  * AVC inherits the upstream CVC's `cvc` characteristic via the `:cvlan` assignment (single-hop), and the NniGroup's `nni_group` characteristic transitively via `[:cvlan, :svlan]` (two-hop). Both singular.
  * CVC inherits the upstream NniGroup's `nni_group` characteristic via the `:svlan` assignment (singular).
  * NniGroup brings up the typed value of every comprised NNI as `nnis[]` via the `:contains` relationship.
  * New `cvc_metrics` characteristic on CVC carries `avcs_count` and `avcs_total_bandwidth` aggregated live over assigned AVCs.
  * New `nni_group_metrics` characteristic on NniGroup carries `cvcs_count`/`cvcs_total_bandwidth` (demand), `nnis_count`/`nnis_total_bandwidth` (capacity), and `utilization = cvcs_total_bandwidth / nnis_total_bandwidth`.
* NBN — NTD brings up assigned UNIs as `unis[]` via the `:port` assignment (issue #49 part 2).
* NBN — NbnEthernet (PRI) brings up four characteristics surfacing the full delivery chain (issue #49 part 3): `avc` single-hop via the `:circuit` owns relationship, `uni` single-hop via the `:port` owns relationship, `cvc` two-hop via `:circuit` then `:cvc`, and `ntd` two-hop via `:port` then `:ntd`. All singular.
* NBN and Access — consumer-side aliases on assignments and relationships now name the **upstream related resource** the consumer is part of (its domain role), not the slot/thing being received. NBN: AVC sets `:cvc` on its cvlan assignment, CVC sets `:nni_group` on its svlan assignment, UNI sets `:ntd` on its port assignment; PRI's two `:owns` relationships are aliased `:circuit` (AVC) and `:port` (UNI). Access: Card sets `:shelf` on its slot assignment, Path sets `:card` on its port assignment, and `Shelf.cards` filters on `alias: :shelf`. Inheritance walks use these consumer-aliases. Pool/metric aggregations are unaffected — they still filter by `thing`.
* `BandwidthProfile.downstream/1` — atom-to-Mbps mapping used by the metrics aggregation. CVCs are treated as symmetric capacity in this model (satellite asymmetry ignored).

### Refactors (continued):
* `DiffoExample.Calculations.InheritedCharacteristic` renamed to `InheritedCharacteristicViaAssignment`; new sibling `InheritedCharacteristicViaRelationship` traverses `Provider.Relationship` edges (forward source → target). Both calcs accept `singular?:` to unwrap to a single value where graph identity guarantees ≤1 result. `InheritedCharacteristicViaRelationship` also accepts a `then_via:` list of assignment aliases to continue the walk via `AssignmentRelationship` after the relationship hop — covers mixed paths like PRI's `cvc` (relationship + assignment).
* `ReverseInheritedCharacteristic` extended with a `thing:` filter option, complementing the existing `alias:` filter. Source-side aggregations should prefer `thing:` since it's always set from the pool DSL — see the assignment-direction-asymmetry rationale.

## [v0.2.2](https://github.com/diffo-dev/diffo/compare/v0.2.1..v0.2.2) (2026-05-21)

### Maintenance:
* updated to diffo 0.4.0 (skipping 0.3.0)
* updated to ash_neo4j 0.6.0
* added ash_ai 0.6 for MCP and future LLM features
* AGENTS.md added with discipline reminders (keep `tools do` aligned with code-interface `define`s; run `mix format` and `reuse lint` before every commit)
* `DiffoExample.DataCase` ExUnit case template — DRYs the AshNeo4j sandbox setup across 7 test files
* `test/support/characteristics.ex` `@characteristic_modules` derived from configured ash_domains at runtime via `Ash.Domain.Info.resources/1` + `Diffo.Provider.Extension.Info.instance?/1`

### Features:
* diffo 0.4.0 migration: unified `provider do` DSL, `pools do`, `AssignmentRelationship`, `Assigner.assign/3` with pool lookup, `relationships do` permitted source/target roles, `Pool.update_pools/3` in define actions
* `DiffoExample.Changes.Define`, `Relate`, `Assign` — three change modules collapsing ~28 hand-written after-action bodies across 11 instance resources into one declarative line per action
* MCP interface via ash_ai (issue #44) — 60 tools exposed across Access and Nbn domains; `/mcp` forwarded from the existing Plug.Cowboy listener on port 4000; setup how-to at `documentation/how_to/setup_mcp.md`
* Bring up characteristics across the assignment graph (issues #10 and #32):
  * `DiffoExample.Calculations.InheritedCharacteristic` — assignee inherits typed characteristic from its assigner via incoming `AssignmentRelationship` traversal (mirrors `Diffo.Provider.Calculations.InheritedPlace`)
  * `DiffoExample.Calculations.ReverseInheritedCharacteristic` — assigner brings up typed characteristic from its assignees via outgoing traversal ("insanity is hereditary, you get it from your kids")
  * `DiffoExample.Access.Calculations.ShelfTotalPorts` — multi-hop aggregate-style calc summing port capacity across a shelf's assigned cards
  * Card surfaces `:shelf`/`:slot`; Path surfaces `:card`/`:port` and (two-hop) `:shelf`; Shelf surfaces `:cards`/`:total_ports`
* Resource lifecycle: `:build` leaves `resource_state` nil; `:define` transitions to `:operating` — minimum needed for the Assigner gate without modelling intermediate planning states (which are better expressed as Plan entities outside the instance)
* `Shelf` and `Path` characteristics gained `:device_name` attribute with JSON rename to `"name"` (parallel to the `Dslam` pattern), so the typed characteristic carries the device's own name without colliding with `BaseCharacteristic`'s role-name `:name`

### Workarounds (raised upstream):
* `DslAccess.qualify_result` transitions to `:inactive` instead of `:feasibilityChecked` — works around the diffo Assigner gating services to `[:active, :inactive]`
* `DiffoExample.Util.summarise_characteristics/2` test-time projection collapses typed characteristics and pool records to `"absent_diffo_169"` placeholders on both sides of JSON comparisons while [diffo#169](https://github.com/diffo-dev/diffo/issues/169) is open
* No JSON rendering yet of inherited / reverse-inherited characteristic calc results — waits on [diffo#173](https://github.com/diffo-dev/diffo/issues/173)

### Upstream yarns raised:
* [diffo#169](https://github.com/diffo-dev/diffo/issues/169) — surface typed characteristics and pools in Instance JSON
* [diffo#170](https://github.com/diffo-dev/diffo/issues/170) — provide change modules for the Define / Relate / Assign patterns
* [diffo#171](https://github.com/diffo-dev/diffo/issues/171) — BaseCharacteristic could generate `update :update accept` from public attributes
* [diffo#172](https://github.com/diffo-dev/diffo/issues/172) — `inherited_characteristic` and `reverse_inherited_characteristic` DSL declarations
* [diffo#173](https://github.com/diffo-dev/diffo/issues/173) — JSON surfacing of inherited and reverse-inherited concepts
* [diffo-dev/ash_neo4j#74](https://github.com/diffo-dev/ash_neo4j/issues/74) — vector index support (enriched with consumer context)

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


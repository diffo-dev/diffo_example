<!--
SPDX-FileCopyrightText: 2025 diffo_example contributors <https://github.com/diffo-dev/diffo_example/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# The Provider Domain

The Provider domain is **diffo's own domain** — the base resources and DSL on top of which Access, NBN, and any other domain you build are written. You've used every Provider primitive in the [Access scenario](access.md) without naming them; this page names what you've been using.

Provider isn't yours to extend. You don't `define` actions on it or relate to its resources directly. You build *with* it.

## What Provider gives you

Every `Instance` resource in your domain (`Shelf`, `Card`, `DslAccess`, `NbnEthernet` …) is a `BaseInstance`-derived Ash resource. `BaseInstance` is a Provider fragment that brings in a complete TMF Service/Resource surface — id, href, lifecycle state, places, parties, characteristics, features, relationships, the JSON encoder, the graph layer. Mix it in and a small DSL on top is enough to model your domain.

The primitives, in the order you met them in the Access scenario:

### Specification

Every `Instance` declares a `Specification` — the *type* of thing it is (`shelf`, `dslAccess`, `nbnEthernet`). Specifications carry a stable id, a name, a category, a description, and the TMF kind (`:serviceSpecification` or `:resourceSpecification`). They show up in every TMF JSON payload as `serviceSpecification` / `resourceSpecification`. You declared one with `specification do … end` inside your `provider do` block.

### Instance

A concrete thing of a specification — a particular `shelf` named "QDONC-0001" with a unique id. You created instances with `:build` actions (e.g. `DiffoExample.Access.build_shelf/1`). Each instance is a node in the graph.

### Characteristic

Typed value slots on an instance — the actual data the consumer cares about. You declared them with `characteristics do characteristic :foo, FooCharacteristic end`. Each is its own little Ash resource (a `BaseCharacteristic`-derived module with attributes and a `:value` calculation), and the Provider encoder lifts it inline as `{name: foo, value: {…}}` in the instance's `serviceCharacteristic` / `resourceCharacteristic` array.

There's a sister kind — **metrics characteristics** — for local, non-inheritable aggregates (e.g. `CvcMetrics.avcs_count`). Same shape; the `:value` calc just reads the graph instead of stored attributes.

### Pool

A range of allocatable values declared on an instance — `:slots`, `:ports`, `:cvlans`, `:pairs`. You declared one with `pools do pool :slots, :slot end`: the first atom names the pool (the AssignableCharacteristic), the second names the *thing* being allocated. Pools surface in JSON as their own characteristic record showing first/last/free/algorithm.

### Assignment

A consumer takes a value from another instance's pool — Card takes a `:slot` from Shelf, Path takes a `:port` from Card, Path takes a `:pair` from Cable. Each assignment is an `AssignmentRelationship` edge with the value and an alias. The **alias is the consumer's name for the upstream related resource it's part of** — Card sets `alias: :shelf` because it's part of a Shelf. That alias is the key for inheritance walks.

### Relationship

Arbitrary edges between instances — `:contains`, `:owns`, `:isPartOf`. You created them with `:relate` actions taking `Relationship` structs. Provider stores these as either `Provider.Relationship` (mutable characteristics) or `DefinedSimpleRelationship` (one frozen characteristic at creation, used by the Assigner). They surface as `resourceRelationship` / `serviceRelationship` entries in JSON.

### Feature

Optional capabilities on an instance (`:dynamic_line_management` on `DslAccess`). Declared with `features do feature :name, is_enabled?: bool end`, optionally carrying their own characteristics.

### Place and Party

Where and who. Declared with `places do … end` and `parties do … end` blocks on an instance, populated by passing `%Place{id, role}` and `%Party{id, role}` structs to build/qualify actions. Surface as TMF `place` and `relatedParty` references.

### State machine

A service carries a lifecycle state machine; a resource carries an independent `lifecycle_state`. A service declares transitions with `state_machine do transitions do … end end` and each transitioning action uses `change transition_state(:new_state)`; a resource sets its TMF639 lifecycle directly, e.g. `change set_attribute(:lifecycle_state, :installed)`. The current state surfaces in JSON as `state` (service) or `lifecycleState` (resource).

## What the encoder does

You never wrote serialiser code. Once your instance has its specification, characteristics, features, places, parties, relationships and lifecycle state, the Provider encoder maps the whole graph into TMF-compliant JSON every time you call `Jason.encode!(instance)`. The order, naming, and nesting conventions all come from the Provider's `jason do` configurations. Customise per resource if you need to; otherwise just declare the model and the JSON shape follows.

## Bringing context up — the inheritance calcs

Provider doesn't (yet) ship the inheritance calculations you used in Access — `Card.shelf`, `Path.card`, `Path.shelf`. Those live in this example codebase as [InheritedCharacteristicViaAssignment](../../lib/diffo_example/calculations/inherited_characteristic_via_assignment.ex) and [InheritedCharacteristicViaRelationship](../../lib/diffo_example/calculations/inherited_characteristic_via_relationship.ex). They're small (one Ash calc each) and worth yarning upstream as Provider primitives — sister calcs to the existing `InheritedPlace` and `InheritedParty` that Provider already ships.

## Going deeper into Provider

This page is an orientation. For a deeper look at Provider itself:

- The [Diffo livebook](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo-dev%2Fdiffo%2Fblob%2Fdev%2Fdiffo.livemd) — walks the Provider concepts directly (Specification, Instance, Feature, Characteristic, Party, Place, Relationship).
- The [Provider Instance Extension livebook](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo-dev%2Fdiffo%2Fblob%2Fdev%2Fdocumentation%2Fhow_to%2Fuse_diffo_provider_instance_extension.livemd) — walks the DSL you used to declare the Access resources.

## What next?

You've seen the primitives in action ([Access](access.md)) and you've seen what they are (here). The next move is to bring your own domain — even a sketch is enough — and model it the way Access does. Start with one specification, declare its characteristics, decide whether anything pools, sketch a build action, and watch the JSON come out the other side.

When you're ready for a richer example, the [NBN domain](nbn.md) revisits the same primitives at scale: multi-tenancy, a longer delivery chain, and the cross-resource inheritance that Access only hinted at.

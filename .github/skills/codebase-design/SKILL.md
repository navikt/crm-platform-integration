---
name: codebase-design
description: 'Use when designing or simplifying Salesforce interfaces, module responsibilities, adapters, factories, package boundaries, or behavioural test seams. Compare small designs before adding abstractions.'
---

# Salesforce codebase design

Use for a bounded design question, not an unsolicited whole-repository refactor.

## Process

1. Read `CONTEXT.md`, applicable `AGENTS.md`, relevant ADRs, and the nearest callers, implementation, and tests. Separate the main package from read-only dependencies.
2. State the observable behaviour and what actually varies: for example real and scenario-based results. Preserve existing public contracts unless an approved migration changes them.
3. Describe the caller-facing contract, including inputs, outcomes, errors, required configuration, sharing, CRUD/FLS, side effects, and transaction constraints. A method signature alone is not the contract.
4. Compare the simplest viable design with one meaningful alternative. Reuse existing interfaces and helpers before adding a class, factory, or configuration layer. Do not create speculative extension points.
5. Apply the removal question to each proposed abstraction: if removed, does its complexity disappear or spread into callers? Keep it when it concentrates real responsibility or provides a required variation point; otherwise simplify.
6. Identify the public behavioural test seam. Prefer tests through the same contract callers use, not private state or test-only branches that bypass actual behaviour.
7. Check Salesforce constraints: SOQL/DML bulk safety, sharing and minimum access, callout/DML ordering, separate UI transactions, cache freshness, governor limits, package visibility, and production activation guards.
8. Present the recommended change, affected files, alternative rejected, tradeoff, tests, and unresolved decisions. Use a small diagram when it clarifies the call flow. Distinguish observed behaviour from proposed behaviour.
9. Obtain human approval for red-zone decisions and consequential contract changes. Hand off agreed behaviour to a spec or focused TDD slice; analysis is not deploy or package authorization.

## Guardrails

- A small caller-facing contract should hide useful complexity, not merely forward every parameter through more layers.
- Keep domain decisions out of transport and mock implementations.
- Retain established Salesforce/Nav terms such as service, adapter, and boundary; do not force a new vocabulary onto existing APIs.
- Use direct analysis by default. Delegate only when the user's request or repository rules justify substantial independent work.
- Do not introduce dynamic class lookup, new dependencies, external reporting services, or whole-codebase restructuring without a concrete requirement.

## Reference

Locally maintained Salesforce guidance informed by [Matt Pocock's codebase-design skill](https://github.com/mattpocock/skills/tree/main/skills/engineering/codebase-design). No upstream installation or network access is required to use this skill.

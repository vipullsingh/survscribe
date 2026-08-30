# ADR-0007 — Engineering Conventions: Testing, Branching, Toolchain and Formatting

- **Status:** Proposed — awaiting project-owner approval (`sprint_0001` §6 DoD)
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Sprint:** `sprint_0001` task 8
- **Closes:** `CLAUDE.md` §13.2 and §16 Q11
- **Numbering note:** originally planned as ADR-0005; renumbered because 0005 (identity model) and 0006 (geo-IP provider) were taken.

---

## Context

`CLAUDE.md` §13.2 lists what the project has deliberately *not* decided: no linter or formatter configuration, no testing framework, no branching strategy, no `.editorconfig`. That was correct while the repository held only documents. The first code has now landed, and every one of those gaps is a decision that will otherwise be made accidentally — by whoever writes the second file, in whatever style they prefer.

The project's own rule (`CLAUDE.md`, "Never assume") is that conventions are decided, not invented in passing. This ADR decides them.

---

## Decisions

### 1. Go version — **1.25**

`go.mod` previously declared `go 1.22`. That line was a placeholder written before any dependency existed, and it does not survive contact with the mandated stack: **`github.com/jackc/pgx/v5` v5.10.0 declares `go 1.25.0`**, and pgx is fixed by ADR-0001 D21. Holding the module at 1.22 would mean pinning pgx and Gin to older releases purely to preserve a number nobody chose.

Adopted: **Go 1.25**, with `gin v1.12.0` and `pgx v5.10.0`. CI pins the same version. `CLAUDE.md` §8's `go 1.22` reference is superseded.

### 2. Backend testing — **standard `testing` + `testify`**

`github.com/stretchr/testify` for assertions (`assert` for soft checks, `require` where a failure makes the rest of the test meaningless). No BDD framework: the domain vocabulary is already precise, and a second layer of English adds nothing.

- Test files sit beside the code as `*_test.go`.
- Package-level tests use the `_test` external package (`package server_test`) so tests exercise the exported surface a caller actually has.
- Test names are sentences describing the guarantee: `TestUnknownRouteReturnsAnEnvelopeNotGinsPlainText`, not `TestNotFound`. A failing test name should tell a reader what broke without opening the file.
- `go test -race` in CI. The backend is a goroutine-per-request server with a shared connection pool and a concurrent media pipeline; a data race here corrupts claim data.
- **A unit test must not require Postgres.** Tests that do belong in an explicitly named integration suite behind a build tag, run against the disposable CI database.

### 3. Mobile testing — **Jest + React Native Testing Library**

Jest via the `react-native` preset; RNTL for component tests, queried by accessible role and label rather than test IDs, so the tests exercise what a screen reader exposes and WCAG 2.1 AA (CR-NF7) does not silently regress.

Detox for end-to-end is deferred until there are flows worth driving — no earlier than `sprint_0005`, when the dashboard and sync engine exist.

### 4. The deterministic loss engine is tested to a higher bar

`CLAUDE.md` §14 constraint 5 makes the Stage 11 arithmetic the highest-risk correctness surface in the product. It is therefore held to a standard nothing else is:

- Pure functions, no I/O, so every case is testable without infrastructure.
- The `physical-schema.md` §30.2 worked example (₹10,00,000 gross → ₹4,97,500 net recommended) is a committed regression test.
- Table-driven cases covering each deduction independently and the full FR-11.2 chain in order.
- **The same cases run against both implementations** — the Go service and the TypeScript client engine — from one shared fixture file. Two engines that disagree about a rupee is exactly the failure the offline architecture invites, and only a shared fixture catches it.
- Money is never a float, in either language, in test or in production.

### 5. Formatting — **Prettier for JS/TS, `gofmt` for Go**

Prettier owns formatting; ESLint owns correctness. No lint rule may express a formatting preference — that argument is settled by the tool, not in review. `printWidth` is 100, because this domain's identifiers (`underinsurance_deduction`, `PreliminarySurveyReport`) wrap badly at 80.

Go uses `gofmt` defaults with no local additions.

`.editorconfig` covers the rest: UTF-8, LF, final newline, trimmed trailing whitespace, 2-space indent (tabs in Go, 4 in SQL). LF matters specifically: development happens on Windows and CI runs on Linux, and mixed line endings would make `git diff --exit-code` — which CI uses to detect stale generated files — fail for the wrong reason.

### 6. Linting — **ESLint 9 flat config, deliberately small**

Shared config in `@survscribe/config`. `js.configs.recommended` plus `typescript-eslint` recommended, with four additions that earn their place:

- `@typescript-eslint/consistent-type-imports` — keeps type-only imports erased, which matters for a bundle shipped to a field device.
- `eqeqeq` — with `null` exempt, because `!= null` is the idiomatic nullish check.
- `no-console` (warn, `warn`/`error` allowed) — a stray `console.log` in this app can print claim data to a device log.
- `no-unused-vars` with an `^_` escape hatch.

`no-floating-promises` is **wanted but not yet enabled**: a dropped promise in the offline sync queue silently loses a surveyor's field work. It requires type-aware linting (`parserOptions.project`), which is a separate change with a real performance cost. Tracked here so it is not forgotten.

Generated files (`packages/types/src/schema.d.ts`, `openapi.yaml`) are lint- and format-ignored. Findings in generated output are fixed in the generator.

### 7. Branching — **short-lived branches off `main`, squash merge**

Every commit to date is on `main`, which was fine for documents and is not fine for code.

- `main` is always releasable and is protected: no direct pushes, CI green before merge.
- Branches: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`, then a short slug — `feat/sprint-0003-auth-login`.
- Short-lived. A branch open longer than a sprint is a merge conflict accruing interest.
- **Squash merge**, so `main` carries one commit per change with a Conventional Commits subject. The existing history already uses Conventional Commits (`feat:`, `docs:`, `chore:`, `design:`); this continues it.
- No release branches yet. Revisit when there is something to release.

### 8. Generated artifacts are committed, and CI proves they are current

`openapi.yaml`, `packages/types/src/schema.d.ts` and `packages/api-contracts/openapi.yaml` are all generated, and all committed. Committing them means a reviewer sees the contract change in the diff, which is the point — an API change that is invisible in review is an API change nobody reviewed.

The risk of committed generated files is staleness, so CI regenerates and fails on any difference. Two rules follow: never hand-edit a generated file, and never commit a change to a source of truth without regenerating.

---

## Consequences

- `go.mod` moves to Go 1.25; `CLAUDE.md` §8's `go 1.22` is stale and is corrected.
- CI gains four jobs: contract integrity, migrations apply-and-roll-back, Go build/vet/test, and workspace lint/typecheck/test.
- Branch protection on `main` needs enabling in GitHub settings — a repository-administration action, not a code change, and not something an agent should perform. **Owner action required.**
- The shared loss-engine fixture (§4) does not exist yet. It is created in `sprint_0011`, the first sprint that implements the engine.

---

## Alternatives considered

**Pinning Go to 1.22 and downgrading pgx.** Rejected: it inverts the dependency, holding a mandated driver back to satisfy a placeholder version line, and buys nothing — there is no deployed environment constraining the toolchain.

**Ginkgo/Gomega for Go tests.** Rejected: the assertions this codebase needs are ordinary, and a DSL would add a dependency plus a dialect for no gain in clarity.

**Trunk-based development with no branches.** Rejected: `main` must stay releasable and CI-green, and a protected `main` requires a pull request, which requires a branch.

**Merge commits instead of squash.** Rejected: work-in-progress commits inside a feature branch are not information anyone will want from `main` in a year, and a linear history makes bisecting a loss-calculation regression tractable.

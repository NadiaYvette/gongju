# gongju — State

Operational frontier. Read with `PLAN.md`; update before ending a session.

## Where we are

The repository skeleton for `gongju` is fully grounded, documented to parity with Polytropos and Penelope, and prepared for Hackage distribution under GHC 9.14.1 / Cabal 3.18.
Both packages (`packages/gongju` and `packages/gongju-text`) pass `cabal check` with 0 errors and 0 warnings, and all 6 physical verification gates pass cleanly.

### Package Architecture
- **`packages/gongju`**: Pure type-level utility functions, variadic composition, positional combinators, arbitrary permutations, Grand Unified Open-World Tape Engine, canonical Hackage ecosystem integrations, Contravariant Syntax Grids, Monadic Curried Binding, and Zero-Cost Core Inspection Fixtures (`Gongju.Peano`, `Gongju.Composition`, `Gongju.Positional`, `Gongju.Permute`, `Gongju.Indexed`, `Gongju.Comonad`, `Gongju.Adjunction`, `Gongju.Kan`, `Gongju.Profunctor`, `Gongju.Contravariant`, `Gongju.Monad`, `Gongju.Core`, `test/CoreInspection.hs`).
- **`packages/gongju-text`**: Structured text utilities, non-empty text refinements, container-polymorphic stanza parsing, and hierarchical indentation layout parsing (`Gongju.Text.NonEmpty`, `Gongju.Text.Stanza`, `Gongju.Text.Layout`, `test/Main.hs`).

### Code Quality & Static Analysis Gates [COMPLETED]
- **Toolchain**: GHC 9.14.1 / Cabal 3.18.1.0 targeting `-Wall -Wcompat -Wredundant-constraints`.
- **HLint Cleanliness**: 0 hints across production source files and test suites under `.hlint.yaml`.
- **Physical Verification**: `./bin/gongju-verify` active with 6 verification gates (HLint, Cabal Test Suite, Zero-Cost GHC Core Inspection, Tagref Cross-References, Markdown Link Integrity, CLOC Comment Density).
- **Git Governance**: `.githooks/commit-msg` enforcing Sarutahiko RFC 2822 commit trailer rules; `.githooks/pre-commit` guarding Tagref and link consistency.
- **Hackage Readiness**: `cabal check` clean (0 errors, 0 warnings) for both `gongju` and `gongju-text`, including full licenses, per-package CHANGELOG.md, per-package README.md, source-repository head stanzas, homepage, bug-reports, and tested-with declarations.

### Active Frontier
- **Documentation Parity & Hackage Preparation [COMPLETED]:**
  - Expanded root `README.md` with Korean etymological grounding (공구 / 工具), toolmaker philosophy, architecture, worked examples across all 10 subsystems, and verification discipline.
  - Expanded `docs/INDEX.md` with complete 13-asset inventory matrix, 6 curated audience reading paths, and multi-package directory catalog.
  - Expanded `docs/NEWBIE_GUIDE.md` with 3-level progressive disclosure funnel, full symbol navigation table for both packages, Peano induction mental model, and quickstart recipes.
  - Expanded `docs/MAINTAINER_GUIDE.md` with invariants I1–I8, 6-gate physical verification discipline, and triage runbooks A–E.
  - Full Hackage metadata and per-package docs in `packages/gongju` and `packages/gongju-text`.
- **Testing Status:** 74/74 tests passing (68 in `gongju`, 6 in `gongju-text`).
- **Verification Status:** All 6 physical verification checks (`bin/gongju-verify`) passing cleanly with 0 warnings, 0 hints, 0 residual Core dictionaries, 0 dangling tagref references, and 0 broken links (131 checked across 27 files).

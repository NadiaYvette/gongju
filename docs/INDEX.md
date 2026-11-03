# gongju Documentation Index & Corpus Inventory

Welcome to the `gongju` technical documentation corpus.

`gongju` (공구 / 工具, tools/implements) provides pure type-level utility functions, Peano induction, variadic arity composition, in-place curried arrow combinators, arbitrary argument permutations, an open-world tape engine, contravariant syntax grids, monadic lifting masks, curried profunctor strand reordering, and structured text utilities.

---

## 1. Corpus Inventory Matrix

| Asset | Path | Genre | Target Audience | Authority | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Project Monograph** | [`README.md`](../README.md) | Overview & Synopsis | All Engineers | Canonical Overview | Current |
| **Documentation Index** | [`docs/INDEX.md`](INDEX.md) | Reading Map & Inventory | All Audiences | Canonical Index | Current |
| **Interactive Tutorial** | [`docs/TUTORIAL.md`](TUTORIAL.md) | Hands-on Tutorial | Developers, API Consumers | Pedagogical Authority | Current |
| **Newbie Quickstart** | [`docs/NEWBIE_GUIDE.md`](NEWBIE_GUIDE.md) | Onboarding & Navigation | New Contributors, AI Agents | Quickstart Authority | Current |
| **Maintainer Guide** | [`docs/MAINTAINER_GUIDE.md`](MAINTAINER_GUIDE.md) | Governance & Operations | Maintainers, Reviewers | Operational Authority | Current |
| **Design Monograph** | [`docs/notes/GONGJU_DESIGN.md`](notes/GONGJU_DESIGN.md) | Design & Architecture | Type Theorists, Architects | Invariant Authority | Current |
| **Doc Strategy Policy** | [`docs/notes/DOC_STRATEGY.md`](notes/DOC_STRATEGY.md) | Documentation Strategy | Authors, Maintainers | Policy Authority | Current |
| **Commit Attribution** | [`docs/notes/COMMIT_ATTRIBUTION.md`](notes/COMMIT_ATTRIBUTION.md) | Git & DCO Policy | Contributors, Subagents | Procedural Authority | Current |
| **AI Assistant Rules** | [`AGENTS.md`](../AGENTS.md) | Machine Instructions | AI Coding Assistants | Operational Mandate | Current |
| **Engineering Plan** | [`PLAN.md`](../PLAN.md) | Strategic Roadmap | Planners, Architects | Planning Authority | Current |
| **Operational State** | [`STATE.md`](../STATE.md) | Session Ledger | Pair Programmers | Dynamic State | Current |
| **`gongju` Core Package** | [`packages/gongju/README.md`](../packages/gongju/README.md) | Package Overview | Library Consumers | Package Authority | Current |
| **`gongju-text` Package** | [`packages/gongju-text/README.md`](../packages/gongju-text/README.md) | Package Overview | Text Processing Consumers | Package Authority | Current |

---

## 2. Curated Audience Reading Paths

### Path A: The First 15 Minutes (Executive / Newcomer)
1. [`README.md`](../README.md) — The Korean etymology (공구 / 工具), high-level motivation, and quickstart examples.
2. [`docs/NEWBIE_GUIDE.md`](NEWBIE_GUIDE.md) — Fast symbol navigation and 15-minute quickstart recipes.
3. [`docs/TUTORIAL.md`](TUTORIAL.md) §1–§4 — Basic variadic composition (`compN`), positional yanking (`slipr`), and permutation (`permute`).

### Path B: Type Theorist & Peano Architect
1. [`docs/notes/GONGJU_DESIGN.md`](notes/GONGJU_DESIGN.md) §1–§2 — Architectural decisions D1–D11, Peano induction, and bidirectional functional dependencies.
2. [`packages/gongju/src/Gongju/Peano.hs`](../packages/gongju/src/Gongju/Peano.hs) — Inductive `Peano` data kind and compile-time `ToPeano`/`FromPeano` type families.
3. [`packages/gongju/src/Gongju/Composition.hs`](../packages/gongju/src/Gongju/Composition.hs) — Bidirectional fundeps in `ComposeN` and `FmapN`.
4. [`docs/MAINTAINER_GUIDE.md`](MAINTAINER_GUIDE.md) §1 — Architectural invariants I1–I8.

### Path C: Functional Combinator & Category Consumer
1. [`docs/TUTORIAL.md`](TUTORIAL.md) §5 — The Grand Unified Open-World Tape Engine (`withOps`, `(.@)`).
2. [`docs/TUTORIAL.md`](TUTORIAL.md) §7–§10 — Categorical integrations: `Comonad`, `Adjunction` dual annihilation (`zapLR`, `zapRL`), `Kan` extensions, and `Profunctor` mapping.
3. [`packages/gongju/src/Gongju/Core.hs`](../packages/gongju/src/Gongju/Core.hs) — Unified re-exports and tape step evaluation.

### Path D: Contravariant & Monad Grid Specialist
1. [`docs/TUTORIAL.md`](TUTORIAL.md) §6 — Contravariant positional pre-composition (`precomposeAt`), 2D function splicing (`spliceAt`), and alternating parity stacks (`contramapN`).
2. [`docs/TUTORIAL.md`](TUTORIAL.md) §11 — Two-phase positional monadic binding (`bindPos`), multi-slot lifting masks (`liftMask`), and arity Kleisli composition (`bindKleisliN`).
3. [`packages/gongju/src/Gongju/Contravariant.hs`](../packages/gongju/src/Gongju/Contravariant.hs) & [`packages/gongju/src/Gongju/Monad.hs`](../packages/gongju/src/Gongju/Monad.hs) — Core implementations.

### Path E: Text Processing & Layout Consumer
1. [`packages/gongju-text/README.md`](../packages/gongju-text/README.md) — Overview of `gongju-text`.
2. [`packages/gongju-text/src/Gongju/Text/NonEmpty.hs`](../packages/gongju-text/src/Gongju/Text/NonEmpty.hs) — Safe non-empty text splitting.
3. [`packages/gongju-text/src/Gongju/Text/Stanza.hs`](../packages/gongju-text/src/Gongju/Text/Stanza.hs) — Stanza grouping and container polymorphism.
4. [`packages/gongju-text/src/Gongju/Text/Layout.hs`](../packages/gongju-text/src/Gongju/Text/Layout.hs) — Indentation measurement and hierarchical block parsing.

### Path F: AI Coding Assistant & Maintainer
1. [`AGENTS.md`](../AGENTS.md) — Operational instructions, token conservation, and two-file loop.
2. [`docs/MAINTAINER_GUIDE.md`](MAINTAINER_GUIDE.md) — Architectural invariants and 6-gate physical verification discipline.
3. [`docs/notes/DOC_STRATEGY.md`](notes/DOC_STRATEGY.md) — Precedence rule (code wins at runtime; notes corrected in the same change set).
4. [`bin/gongju-verify`](../bin/gongju-verify) — Automated verification test runner.

---

## 3. Package Directory Catalog

- **[`packages/gongju/`](../packages/gongju/)**: Core library containing pure type-level utilities:
  - `Gongju.Core`: Top-level re-exports and the Grand Unified Tape Engine.
  - `Gongju.Peano`: Structural Peano numbers, TypeLits bridge.
  - `Gongju.Composition`: Variadic composition and nested functor mapping.
  - `Gongju.Positional`: In-place curried arrow combinators (`slipr`, `slipl`, `twist`).
  - `Gongju.Permute`: Curried argument permutations via iterated yanking.
  - `Gongju.Indexed`: Indexed functor, applicative, monad, comonad.
  - `Gongju.Comonad`: Comonad, distributive, and representable integrations.
  - `Gongju.Adjunction`: Categorical adjunctions and dual annihilation (`zapLR`, `zapRL`).
  - `Gongju.Kan`: Right/Left Kan extensions, Yoneda and Codensity fusion.
  - `Gongju.Profunctor`: Profunctor mapping, CurriedCat, tuple-spine and strand permutations.
  - `Gongju.Contravariant`: Positional pre-composition, splicing, alternating parity.
  - `Gongju.Monad`: Positional monadic binding, multi-slot lifting masks, Kleisli composition.
- **[`packages/gongju-text/`](../packages/gongju-text/)**: Text processing library:
  - `Gongju.Text.NonEmpty`: Non-empty text refinements and safe splitting (`wordsNE`, `linesNE`).
  - `Gongju.Text.Stanza`: Polymorphic stanza chunking.
  - `Gongju.Text.Layout`: Indentation measurement and hierarchical block trees.

---

## 4. Physical Verification Gate Discipline

Every change set must pass all 6 physical verification gates:

```bash
./bin/gongju-verify
```

1. **Gate 1: HLint Static Analysis** (`.hlint.yaml`)
2. **Gate 2: Full Cabal Test Suite** (`cabal test all`)
3. **Gate 3: Zero-Cost Core Inspection** (`bin/gongju-inspect-core`)
4. **Gate 4: Tagref Cross-Reference Gate** (`bin/gongju-tagref`)
5. **Gate 5: Markdown Link Integrity Gate** (`bin/gongju-linkcheck`)
6. **Gate 6: CLOC Comment Density Gate** (`bin/gongju-cloc`)

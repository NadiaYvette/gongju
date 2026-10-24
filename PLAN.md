# gongju — Strategic Roadmap (`PLAN.md`)

**Status:** ACTIVE STRATEGIC ROADMAP · October 2026  
**Scope:** Pure Type-Level Utility Combinators & Curried Function Manipulation  
**Canonical Anchor:** Linked to upstream ecosystem standardization [`../PLAN.md` §1](../PLAN.md#1-project-skeleton-&-configuration-propagation-infrastructure-gachi)  

---

## Phase 1: Core Combinators & TypeLits Induction [COMPLETED]

- [x] **Milestone 1.1:** Peano TypeLits Bridge (`Gongju.Peano`)
  - `Peano` data kind, closed type families `ToPeano` and `FromPeano`.
  - Grounded Note [Peano TypeLits Bridge] `[ref:note-peano-typelits-bridge]`.
- [x] **Milestone 1.2:** Variadic Arity Composition (`Gongju.Composition`)
  - `ComposeN` with bidirectional fundeps, `compN @n`.
  - `FmapN` nested functor mapping, `fmapN @n`.
  - Grounded Note [Variadic Composition Bidirectional Fundeps] `[ref:note-variadic-composition-fundeps]`.
- [x] **Milestone 1.3:** Positional Curried Arrow Manipulation (`Gongju.Positional`)
  - `Yank` / `slipr @n`, `Shove` / `slipl @n`, `Twist` / `twist @n`.
  - Grounded Note [Positional Curried Arrow Manipulation] `[ref:note-positional-arrow-manipulation]`.
- [x] **Milestone 1.4:** Arbitrary Permutations & Heterogeneous Bundling (`Gongju.Permute`, `Gongju.HList`)
  - `Permute` / `permute @ns` via iterated `Yank` and `Adjust`.
  - `HList`, `curryH`, `uncurryH`, `ArgsOf`, `ResultOf`.
  - Grounded Note [Iterated Yank Index Adjustment] `[ref:note-iterated-yank-adjustment]`.
- [x] **Milestone 1.5:** Turnkey Verification Suite
  - 5-gate physical verification harness (`bin/gongju-verify`).
  - Hspec test suite passing 12/12 specifications.

---

## Phase 2: Two-Dimensional Contravariant & Monad Grids

- [ ] **Milestone 2.1:** Contravariant Syntax Grids
  - Multi-argument contravariant combinators (`ContravariantN`).
  - Type-safe argument pre-processing.
- [ ] **Milestone 2.2:** Monadic Curried Binding
  - Arity-indexed monadic composition and Kleisli lifting across curried functions.

---

## Phase 3: Integration with Polytropos & Kernmantle Ropes

- [ ] **Milestone 3.1:** Profunctor Effect Handler Permutations
  - Permuting argument orders for binary profunctor strands in `kernmantle-polytropos`.
- [ ] **Milestone 3.2:** Zero-Cost GHC Core Inspection
  - Verify that GHC Core simplifies `permute` and `compN` into direct inlined lambda applications with zero runtime dictionary dispatch.

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
- [x] **Milestone 1.4:** Arbitrary Permutations & Grand Unified Tape Engine (`Gongju.Permute`, `Gongju.Composition`, `Gongju.Indexed`, `Gongju.Comonad`, `Gongju.Adjunction`, `Gongju.Kan`, `Gongju.Profunctor`)
  - `Permute` / `permute @ns` via iterated `Yank` and `Adjust`.
  - Open-world tape execution via `StepPathMask`, `StepRole`, visible `(.@)`, and `withOps`.
  - Canonical Hackage alignment: `comonad`, `distributive`, `adjunctions` (`zapLR`/`zapRL`), `indexed` (`IxFunctor`, `IxApplicative`, `IxMonad`), `kan-extensions` (`Ran`, `Lan`, `Yoneda`, `Codensity`), and `profunctors` (`dimap`, `P1`, `P2`).
  - Grounded Note [Iterated Yank Index Adjustment] `[ref:note-iterated-yank-adjustment]`.
- [x] **Milestone 1.5:** Turnkey Verification Suite
  - 5-gate physical verification harness (`bin/gongju-verify`).
  - Hspec test suite passing 28/28 specifications across all 9 modules.

---

## Phase 2: Two-Dimensional Contravariant & Monad Grids

- [x] **Milestone 2.1:** Contravariant Syntax Grids (`Gongju.Contravariant`)
  - Multi-argument contravariant combinators (`ContravariantN`, `ContramapN`).
  - Positional pre-composition (`PrecomposeAt`, `precomposeAt @n`, `(-.)`, `(-.*)`, `(-.**)`, `(-.***)`).
  - 2D function splicing grid (`SpliceAt`, `spliceAt @n @m`).
  - Alternating parity stacks (`(<-$>)`, `(<-$$>)`, `(<-$$$>)`, `(<-$$$$>)`).
  - Canonical `Contravariant`, `Divisible`, and `Decidable` re-exports.
  - Grounded Note [Contravariant Positional Pre-Composition] `[ref:note-contravariant-precomposition]`.
  - Grounded Note [Contravariant Functor Alternating Parity] `[ref:note-contravariant-alternating-parity]`.
- [x] **Milestone 2.2:** Monadic Curried Binding (`Gongju.Monad`)
  - Two-phase positional monadic binding (`BindAfter`, `BindPos`, `bindPos`, `bindAt`).
  - Classic curried monadic operators: tail binds (`(==<<)`, `(===<<)`, `(====<<)`, `(>>==)`, `(>>===)`, `(>>====)`) and interior binds (`(=.=<<)`, `(==.<<)`, `(=..<<)`, `(>>=.=)`, `(>>.==)`, `(>>..=)`).
  - Multi-slot monadic lifting masks (`LiftMask`, `liftMask`, `ArgMode(Pure, Monadic)`).
  - Arity-indexed Kleisli composition and pure lifting (`liftPureN`, `bindKleisliN`, `(<=<.)`, `(<=<..)`, `(.>=>)`, `(..>=>)`).
  - Grounded Note [Positional Monadic Curried Binding] `[ref:note-positional-monadic-binding]`.
  - Grounded Note [Multi-Slot Monadic Lifting Masks] `[ref:note-multislot-monadic-masks]`.

---

## Phase 3: Integration with Polytropos & Kernmantle Ropes

- [ ] **Milestone 3.1:** Profunctor Effect Handler Permutations
  - Permuting argument orders for binary profunctor strands in `kernmantle-polytropos`.
- [ ] **Milestone 3.2:** Zero-Cost GHC Core Inspection
  - Verify that GHC Core simplifies `permute` and `compN` into direct inlined lambda applications with zero runtime dictionary dispatch.

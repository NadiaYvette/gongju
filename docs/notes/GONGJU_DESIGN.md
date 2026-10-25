# GONGJU_DESIGN.md — Architectural Decisions & Type-Level Invariants

Canonical design monograph for `gongju`.

---

## 1. Design Vision & Linguistic Etymology

`gongju` (공구 / 工具) takes its name from the Korean word for **"tools"** or **"implements"**. In the ecosystem, `gongju` serves as the foundational type-level utility toolset, providing zero-overhead combinators for curried function manipulation, arity composition, and structural argument permutation.

Historically, Haskell developers seeking multi-argument function manipulation faced two unpalatable compromises:
1. **Template Haskell Code Generation (e.g. `composition-extra`):** Generating hundreds of lines of static splices for fixed arities ((.:), (..:), (...:)), which bloat compilation times, fail to abstract dynamically across arity boundaries, and resist higher-order composition.
2. **Generic Tuple Coercion (e.g. `tuple-sop`):** Converting curried functions into $n$-tuples using `Generics.SOP`, which imposes arbitrary tuple-size limits, breaks bidirectional type inference across curry/uncurry boundaries, and fails on duplicate argument types (e.g. `Int -> String -> Int -> r`).

`gongju` resolves both issues by combining:
* **Structural Induction on Peano Naturals:** Driving clean, non-overlapping typeclass resolution.
* **Bidirectional Functional Dependencies:** Propagating type constraints forward from inputs and backward from results.
* **Ergonomic TypeLits Bridging:** Exposing user-facing `@n` type applications backed by inductive Peano terms.

---

## 2. Canonical Architectural Decisions

### D1: Bridging TypeLits to Inductive Peano Naturals
- **Decision:** Call-site ergonomics accept numeric `GHC.TypeLits.Nat` literals (@0, @1, @2), which closed type families ('ToPeano', 'FromPeano') map to structural 'Peano' data kinds ('Z, 'S p).
- **Rationale:** GHC's constraint solver cannot pattern match inductively on `n + 1` for `Nat`, but structural induction over `Peano` terms proceeds deterministically without overlapping instances.
- **Reference:** Note [Peano TypeLits Bridge] `[ref:note-peano-typelits-bridge]`.

### D2: Bidirectional Functional Dependencies for Arity Composition
- **Decision:** The 'ComposeN' typeclass enforces bidirectional fundeps `n b c g -> f`, `n f -> c`, and `n f b -> g`.
- **Rationale:** Ensures type inference flows symmetrically: from the input functions into the composite type, and backward from expected return types into polymorphic inputs.
- **Reference:** Note [Variadic Composition Bidirectional Fundeps] `[ref:note-variadic-composition-fundeps]`.

### D3: In-Place Curried Arrow Manipulation (Yank, Shove, Twist)
- **Decision:** Positional combinators operate directly upon curried function arrows `(a -> r)` without allocating intermediate tuple or list representations.
- **Rationale:** Eliminates runtime allocation overhead and preserves zero-cost compiler inlining.
- **Reference:** Note [Positional Curried Arrow Manipulation] `[ref:note-positional-arrow-manipulation]`.

### D4: Iterated Yank with Dynamic Index Adjustment for Permutation
- **Decision:** Arbitrary curried permutations ('Permute') are computed by sequentially yanking arguments to the head and shifting subsequent indices via 'Adjust'.
- **Rationale:** Supports functions of arbitrary arities, handles duplicate argument types without ambiguity, and permits partial permutations where unspecified arguments retain their original relative order.
- **Reference:** Note [Iterated Yank Index Adjustment] `[ref:note-iterated-yank-adjustment]`.

### D5: Grand Unified Open-World Tape Engine
- **Decision:** Multi-layer functor and monad/comonad composition is modeled as an open-world tape machine using `StepPathMask`, `StepRole`, and open layer/mode tags (`F`, `C`, `B1`, `B2`, `BB`, `P1`, `P2`, `IxF`, `Dist`, `PP`, `PZ`, `PL`, `PM`, `J`, `CS`, `SwapAt`, `PullRet`, `PIM`, `IJ`, `PIxW`, `IxDup`, `IxEx`, `PW`, `PWL`, `Dup`, `Ex`) evaluated via visible-forall entry points (`composeUnifiedV`, `withOps`, `(.@)`).
- **Rationale:** Eliminates closed `HList` isomorphisms in favor of zero-orphan open-world execution over curried functions, supporting generalized effects including standard functors/monads, indexed state/monads (`Gongju.Indexed`), and comonadic/distributive effects (`Gongju.Comonad`).

### D6: Zero-Warning Compiler Verification
- **Decision:** Every package in `gongju` compiles under `-Wall -Wcompat -Wredundant-constraints` and clean HLint hints.
- **Precedence Rule:** Per `DOC_STRATEGY.md` §4, code wins at runtime; when code changes contradict this document, this document must be corrected in the same commit.

---

## 3. Grounded Notes Architecture

- **Note [Peano TypeLits Bridge]** (`Gongju.Peano`):  
  [ref:note-peano-typelits-bridge]  
  Specifies the closed type family conversion bridging ergonomic `GHC.TypeLits.Nat` numbers to inductive `Peano` terms.
- **Note [Variadic Composition Bidirectional Fundeps]** (`Gongju.Composition`):  
  [ref:note-variadic-composition-fundeps]  
  Details the bidirectional functional dependencies driving inductive arity composition.
- **Note [Positional Curried Arrow Manipulation]** (`Gongju.Positional`):  
  [ref:note-positional-arrow-manipulation]  
  Formalizes positional arrow combinators (Yank, Shove, Twist) operating directly on curried functions.
- **Note [Iterated Yank Index Adjustment]** (`Gongju.Permute`):  
  [ref:note-iterated-yank-adjustment]  
  Details index adjustment mathematics for decomposed permutations over curried functions.

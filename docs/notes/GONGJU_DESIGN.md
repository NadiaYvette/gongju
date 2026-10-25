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

### D7: Canonical Hackage Ecosystem Integration (Kmettverse Alignment)
- **Decision:** Rather than retaining homebrew or isolated categorical classes, Gongju directly imports, implements open tape steps for, and re-exports the canonical Hackage classes:
  - `Control.Comonad.Comonad` from `comonad`
  - `Data.Distributive.Distributive` from `distributive`
  - `Data.Functor.Rep.Representable` and `Data.Functor.Adjunction.Adjunction` from `adjunctions`
  - `Data.Functor.Indexed` (`IxFunctor`, `IxPointed`), `Control.Monad.Indexed` (`IxApplicative`, `IxMonad`), and `Control.Comonad.Indexed` (`IxComonad`) from `indexed`
  - `Data.Functor.Kan.Lan` (`Lan`), `Data.Functor.Kan.Ran` (`Ran`), `Data.Functor.Yoneda` (`Yoneda`), `Data.Functor.Coyoneda` (`Coyoneda`), `Control.Monad.Codensity` (`Codensity`), and `Control.Comonad.Density` (`Density`) from `kan-extensions`
  - `Data.Profunctor.Profunctor` from `profunctors` and `Data.Profunctor.Indexed.IxProfunctor` from `indexed-profunctors`
- **Rationale:** Enables prevalent real-world usage patterns to benefit from Gongju's tape engine (`.@`, `withOps`) without orphan instances or artificial wrapper newtypes.

### D8: Two-Dimensional Contravariant Syntax Grids & Alternating Parity
- **Decision:** Multi-argument contravariant combinators collapse into two inductive typeclasses with bidirectional fundeps ('PrecomposeAt' and 'SpliceAt') alongside nested contravariant functor mapping ('ContramapN').
- **Rationale:** Positional pre-composition parameterizes along argument position $n$ and spliced arity $m$, avoiding Template Haskell explosion while ensuring full bidirectional type inference. Nested contravariant mapping flips arrow variance at each layer, automatically tracking parity cancellation across inductive steps.

### D9: Two-Phase Positional Monadic Binding and Multi-Slot Masks
- **Decision:** Interior and trailing monadic binds collapse into a two-phase induction pipeline ('BindAfter' floating trailing pure arguments outside '(>>=)' and 'BindPos' skipping leading arguments) accompanied by arbitrary multi-slot boolean lifting masks ('LiftMask') and arity Kleisli composition ('bindKleisliN').
- **Rationale:** Replaces hundreds of fixed Template Haskell monadic operators ('Control.Monad.Syntax.Two' through '.Six') with two typeclasses maintaining bidirectional functional dependencies. 'LiftMask' allows arbitrary combinations of pure and monadic parameters in a single pass without intermediate tuple packaging.

### D10: Curried Category & Tuple-Spine Profunctor Permutations
- **Decision:** Profunctor effect handler permutations decouple into curried environment parameter permutations ('permuteHandler' via 'Permute'), point-free curried category spine reordering ('CurriedCat', 'yankCat', 'permuteCat'), and right-nested tuple spine arrow permutations ('YankTuple', 'PermuteTuple', 'permuteInputs', 'permuteOutputs', 'dimapPermute').
- **Rationale:** Supports arrow and profunctor effect frameworks (such as 'kernmantle-polytropos') where strands consume multi-argument inputs structured as nested tuples or where effect handlers take curried configuration parameters, eliminating intermediate constructor allocations and runtime dictionary overhead.

### D11: Zero-Cost Inlining & Core Verification
- **Decision:** Every inductive typeclass method across Gongju is annotated with '{-# INLINE #-}' and backed by concrete Peano reduction, guaranteeing that GHC's Simplifier under '-O2' eliminates all typeclass dictionaries, intermediate closures, and tuple allocations, beta-reducing pipelines into direct lambda applications.
- **Rationale:** Verifies mechanically that Gongju incurs zero runtime overhead compared to hand-written monomorphic functions, achieving zero-cost abstraction for high-arity composition and permutation.
- **Reference:** Note [Zero-Cost Inlining and Core Simplification] `[ref:note-zero-cost-core-simplification]`.

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
- **Note [Contravariant Positional Pre-Composition]** (`Gongju.Contravariant`):  
  [ref:note-contravariant-precomposition]  
  Formalizes positional pre-composition ('PrecomposeAt') and 2D function splicing ('SpliceAt') across curried function argument arrows.
- **Note [Contravariant Functor Alternating Parity]** (`Gongju.Contravariant`):  
  [ref:note-contravariant-alternating-parity]  
  Formalizes bidirectional functional dependencies and arrow-flipping parity swap in nested contravariant functor stacks ('ContramapN').
- **Note [Positional Monadic Curried Binding]** (`Gongju.Monad`):  
  [ref:note-positional-monadic-binding]  
  Details two-phase structural Peano induction ('BindAfter' and 'BindPos') floating trailing pure arguments outside '(>>=)' to bind interior and trailing monadic arguments.
- **Note [Multi-Slot Monadic Lifting Masks]** (`Gongju.Monad`):  
  [ref:note-multislot-monadic-masks]  
  Formalizes multi-slot argument lifting masks ('LiftMask', 'ArgMode') transforming any arbitrary subset of curried arguments into monadic inputs in a single pass.
- **Note [Profunctor Effect Handler Permutations]** (`Gongju.Profunctor`):  
  [ref:note-profunctor-handler-permutations]  
  Formalizes curried category spine generalization ('CurriedCat', 'yankCat', 'permuteCat') and environment parameter permutation ('permuteHandler', 'compHandlerN') for profunctor effect handlers.
- **Note [Tuple-Spine Arrow Permutations]** (`Gongju.Profunctor`):  
  [ref:note-tuple-spine-permutations]  
  Formalizes structural induction ('YankTuple', 'PermuteTuple') and profunctor input/output spine permutations ('permuteInputs', 'permuteOutputs', 'dimapPermute') over right-nested arrow tuples.
- **Note [Zero-Cost Inlining and Core Simplification]** (`Gongju.Core`):  
  [ref:note-zero-cost-core-simplification]  
  Formalizes compiler inlining invariants, compile-time Peano reduction, and dictionary elimination verifying zero runtime overhead via automated GHC Core inspection.



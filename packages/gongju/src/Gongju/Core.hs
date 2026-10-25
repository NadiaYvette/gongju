-- | Module: Gongju.Core
-- Description: Core re-exports and introductory guide for Gongju
--
-- 'Gongju' (공구 / 工具, tools/implement) is a pure type-level Haskell utility suite
-- replacing Template Haskell splices (like 'composition-extra') and finite tuple
-- generics (like 'tuple-sop') with an open-world tag-driven tape engine, Peano
-- induction, bidirectional functional dependencies, and arbitrary curried argument
-- manipulation.
--
-- = When to Use This Library
--
-- * **Grand Unified Composition:** Infix tape-driven composition with visible type arguments
--   (@(f .@ [P, P, M]) g@ or @withOps [P, Z, J] f g@).
-- * **Variadic Arity Composition:** Composing unary functions with functions of arbitrary arities
--   (@compN @3@ instead of Template Haskell @(...:)@).
-- * **Positional Argument Manipulation:** Pulling arguments to the front (@slipr @2@), shoving them
--   deeper (@slipl @2@), or transposing adjacent arguments (@twist @1@).
-- * **Arbitrary Argument Permutations:** Specifying a desired argument order as a type-level
--   index list (@permute @'[2, 0, 1]@).
-- * **Indexed Monads & Comonads:** Composing transition-carrying indexed arrows with zero orphans.
-- * **Distributive & Representable Functors:** Commuting infinite streams and comonads outside
--   representable layers without requiring Traversable instances.
--
-- = Worked Example
--
-- >>> import Gongju.Core
-- >>> :set -XTypeApplications -XDataKinds -XRequiredTypeArguments
-- >>> -- 1. Tape-driven composition: mapping and zipping arguments
-- >>> let add3 x y z = (x + y + z :: Int)
-- >>> ((+ 100) .@ [P, P, P]) add3 10 20 30
-- 160
-- >>> -- 2. Reordering curried arguments via indexed mode tags:
-- >>> let tuple3 x y z = (x, y, z)
-- >>> (id .@ [2 # P, 0 # P, 1 # P]) tuple3 True (42 :: Int) "hello"
-- (42,"hello",True)
-- >>> -- 3. Positional argument manipulation:
-- >>> slipr @1 (-) 5 20
-- 15
--
-- = Zero-Cost Compiler Invariants
--
-- All inductive typeclasses in Gongju ('ComposeN', 'Permute', 'Yank', 'Shove', 'Twist',
-- 'PrecomposeAt', 'SpliceAt', 'BindPos', 'BindAfter', 'LiftMask', 'PermuteTuple', 'CurriedCat')
-- are aggressively annotated with '{-# INLINE #-}'. Under GHC's Simplifier (@-O2@),
-- all typeclass dictionary passing, Peano induction, and intermediate tuples/records
-- evaporate completely into direct inlined lambda applications with zero runtime overhead.
--
-- See Note [Zero-Cost Inlining and Core Simplification] [ref:note-zero-cost-core-simplification].

{- Note [Zero-Cost Inlining and Core Simplification]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-zero-cost-core-simplification]
Gongju replaces Template Haskell arity generators and runtime tuple coercions with
pure typeclass induction over structural Peano numbers. A critical architectural
invariant is that this high-level inductive machinery must incur zero runtime overhead:
when compiled under '-O2', every Gongju combinator pipeline must simplify in GHC Core
into the exact same lambda terms as hand-written, specialized functions.

This zero-cost guarantee is achieved through three cooperating invariants:
  1. Aggressive Inlining: Every inductive method ('composeN'', 'yank'', 'shove'',
     'twist'', 'permute'', 'precomposeAt'', 'spliceAt'', 'bindPos'', 'bindAfter'',
     'liftMask', 'yankTuple'', 'permuteTuple'', 'yankCat'', 'permuteCat'') is annotated
     with '{-# INLINE #-}'.
  2. Static Resolution of Peano Depths: Because TypeLits literals (@2, @3, @'[2, 0, 1])
     are resolved to concrete Peano terms ('Z, 'S 'Z, ...) at compile time, the instance
     search is completely known and terminated during typechecking.
  3. Beta-Reduction and Dictionary Elimination: Under GHC's Simplifier (-O2), the
     inlined dictionary methods unroll statically into direct lambda applications.
     Intermediate records and typeclass dictionaries ($fComposeN, $fPermute, $fYank,
     $fPrecomposeAt, $fBindPos, $fYankTuple) are completely eliminated via beta-reduction,
     yielding pure nested function applications and tuple projections with zero allocations
     and zero indirect calls.

This invariant is mechanically verified on every build by the automated Core inspection
gate ('bin/gongju-inspect-core' and 'packages/gongju/test/CoreInspection.hs').
-}
module Gongju.Core
  ( -- * Peano Naturals & Type-Level List Utilities
    module Gongju.Peano
    -- * Guarded Positional Combinators
  , module Gongju.Positional
    -- * Arbitrary Argument Permutations
  , module Gongju.Permute
    -- * Grand Unified Tape Composition Engine
  , module Gongju.Composition
    -- * Indexed Functors, Monads, and Comonads
  , module Gongju.Indexed
    -- * Comonads, Distributive, and Representable Functors
  , module Gongju.Comonad
    -- * Adjunction Transitions and Dual Annihilation
  , module Gongju.Adjunction
    -- * Kan Extensions, Yoneda, and Codensity Fusion
  , module Gongju.Kan
    -- * Profunctors and Indexed Profunctors
  , module Gongju.Profunctor
    -- * Contravariant Syntax Grids & Variance-Flipping Stacks
  , module Gongju.Contravariant
    -- * Positional Monadic Binding & Lifting Masks
  , module Gongju.Monad
  ) where

import Gongju.Peano
import Gongju.Positional
import Gongju.Permute
import Gongju.Composition
import Gongju.Indexed
import Gongju.Comonad
import Gongju.Adjunction
import Gongju.Kan
import Gongju.Profunctor
import Gongju.Contravariant
import Gongju.Monad

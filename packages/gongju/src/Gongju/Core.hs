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
  ) where

import Gongju.Peano
import Gongju.Positional
import Gongju.Permute
import Gongju.Composition
import Gongju.Indexed
import Gongju.Comonad

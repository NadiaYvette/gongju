-- | Module: Gongju.Core
-- Description: Core re-exports and introductory guide for Gongju
--
-- 'Gongju' (공구 / 工具, tools/implement) is a pure type-level Haskell utility suite
-- replacing Template Haskell splices (like 'composition-extra') and finite tuple
-- generics (like 'tuple-sop') with typeclass induction over Peano naturals, bidirectional
-- functional dependencies, and curried argument manipulation.
--
-- = When to Use This Library
--
-- * **Variadic Arity Composition:** Composing unary functions with functions of arbitrary arities
--   (@compN @3@ instead of Template Haskell @(...:)@).
-- * **Positional Argument Manipulation:** Pulling arguments to the front (@slipr @2@), shoving them
--   deeper (@slipl @2@), or transposing adjacent arguments (@twist @1@).
-- * **Arbitrary Argument Permutations:** Specifying a desired argument order as a type-level
--   index list (@permute @'[2, 0, 1]@).
-- * **First-Class Heterogeneous Argument Bundles:** Converting between curried arrows and
--   'HList' via 'curryH' and 'uncurryH'.
--
-- = Worked Example
--
-- >>> import Gongju.Core
-- >>> :set -XTypeApplications -XDataKinds
-- >>> -- 1. Arity composition: (show .) with a 3-argument function
-- >>> let add3 x y z = (x + y + z :: Int)
-- >>> (compN @3 show add3) 10 20 30
-- "60"
-- >>> -- 2. Reordering curried arguments:
-- >>> let f x y z = (x, y, z)
-- >>> permute @'[2, 0, 1] f True "hello" (42 :: Int)
-- (42,True,"hello")
module Gongju.Core
  ( -- * Peano Naturals & TypeLits Bridge
    module Gongju.Peano
    -- * Arity Composition & Functor Mapping
  , module Gongju.Composition
    -- * Positional Combinators
  , module Gongju.Positional
    -- * Argument Permutation
  , module Gongju.Permute
    -- * Heterogeneous Lists & Currying Isomorphism
  , module Gongju.HList
  ) where

import Gongju.Peano
import Gongju.Composition
import Gongju.Positional
import Gongju.Permute
import Gongju.HList

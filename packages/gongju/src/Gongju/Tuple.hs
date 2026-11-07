{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Tuple
-- Description: Zero-cost currying isomorphisms and homogeneous tuple mapping
--
-- This module provides bidirectional isomorphisms between flat GHC tuples
-- and curried functions ('TupleCurry'), as well as homogeneous tuple
-- mapping and traversal combinators ('TupleHom') built directly on 'Gongju.Diagonal'.
--
-- = Architectural Context
--
-- Per Note [Gongju Combinator Taxonomy] [ref:note-gongju-combinators], flat tuples
-- in Haskell often require cumbersome boilerplate (or heavy dependencies like
-- @tuple-sop@) to map, traverse, or convert to curried forms.
-- 'Gongju.Tuple' solves this at zero runtime overhead using Peano-indexed
-- typeclass functional dependencies and unboxed GHC tuple constructors.
--
-- == Invariants & Guarantees
--
-- 1. __Zero-Cost Inlining:__ All operations ('curryFlat', 'uncurryFlat', 'mapTupleHom',
--    'traverseTupleHom') are marked with @{-# INLINE #-}@ and eliminate to flat
--    constructor/pattern matching in GHC Core.
-- 2. __Purity & Totality:__ All operations are referentially transparent and total;
--    no partial functions or runtime errors exist in this module.
-- 3. __Preservation of Homogeneity:__ 'mapTupleHom' and 'traverseTupleHom'
--    guarantee that the structure and arity of homogeneous tuples are preserved.
--
-- = Worked Examples
--
-- >>> curryFlat (\(a, b) -> a + b) 10 20
-- 30
--
-- >>> uncurryFlat (+) (10, 20)
-- 30
--
-- >>> mapTupleHom (* 10) (1, 2, 3)
-- (10, 20, 30)
--
-- >>> traverseTupleHom Just (1, 2, 3)
-- Just (1, 2, 3)
module Gongju.Tuple
  ( -- * 1. Flat Tuple <-> Curried Arrow Bridge (`curryFlat`, `uncurryFlat`)
    TupleCurry (..)
    -- * 2. Homogeneous Flat Tuple Mapping & Traversal (`mapTupleHom`, `traverseTupleHom`)
  , TupleHom (..)
  ) where

import Gongju.Core (Peano (..))
import Gongju.Diagonal (onN, onMN)

--------------------------------------------------------------------------------
-- 1. Bidirectional Flat Tuple Currying Isomorphism
--------------------------------------------------------------------------------

-- | Typeclass establishing a bidirectional currying isomorphism between an
--   @n@-tuple @tup@ returning @r@ and its curried arrow representation @fn@.
--
--   The functional dependencies enforce that the tuple type and result uniquely
--   determine the Peano arity @n@ and curried function @fn@, and vice versa.
class TupleCurry (n :: Peano) tup r fn
  | tup r -> n fn
  , n fn -> tup r
  where
  -- | Converts a function over a flat tuple into its curried equivalent.
  --
  --   >>> curryFlat (\(x, y, z) -> x + y + z) 1 2 3
  --   6
  curryFlat   :: (tup -> r) -> fn

  -- | Converts a curried function into a function over a flat tuple.
  --
  --   >>> uncurryFlat (\x y z -> x + y + z) (1, 2, 3)
  --   6
  uncurryFlat :: fn -> (tup -> r)

-- | 2-tuple isomorphism: @(a, b) -> r@ <-> @a -> b -> r@.
instance TupleCurry ('S ('S 'Z)) (a, b) r (a -> b -> r) where
  curryFlat f a b = f (a, b)
  uncurryFlat f (a, b) = f a b
  {-# INLINE curryFlat #-}
  {-# INLINE uncurryFlat #-}

-- | 3-tuple isomorphism: @(a, b, c) -> r@ <-> @a -> b -> c -> r@.
instance TupleCurry ('S ('S ('S 'Z))) (a, b, c) r (a -> b -> c -> r) where
  curryFlat f a b c = f (a, b, c)
  uncurryFlat f (a, b, c) = f a b c
  {-# INLINE curryFlat #-}
  {-# INLINE uncurryFlat #-}

-- | 4-tuple isomorphism: @(a, b, c, d) -> r@ <-> @a -> b -> c -> d -> r@.
instance TupleCurry ('S ('S ('S ('S 'Z)))) (a, b, c, d) r (a -> b -> c -> d -> r) where
  curryFlat f a b c d = f (a, b, c, d)
  uncurryFlat f (a, b, c, d) = f a b c d
  {-# INLINE curryFlat #-}
  {-# INLINE uncurryFlat #-}

-- | 5-tuple isomorphism: @(a, b, c, d, e) -> r@ <-> @a -> b -> c -> d -> e -> r@.
instance TupleCurry ('S ('S ('S ('S ('S 'Z))))) (a, b, c, d, e) r (a -> b -> c -> d -> e -> r) where
  curryFlat f a b c d e = f (a, b, c, d, e)
  uncurryFlat f (a, b, c, d, e) = f a b c d e
  {-# INLINE curryFlat #-}
  {-# INLINE uncurryFlat #-}

--------------------------------------------------------------------------------
-- 2. Homogeneous Tuple Distribution (Built Directly on `Gongju.Diagonal`)
--------------------------------------------------------------------------------

-- | Typeclass for homogeneous tuples whose component slots all share a single
--   element type @a@, supporting mapping to @tupB@ (with element type @b@)
--   and Applicative traversal.
class TupleHom tupA tupB a b | tupA -> a, tupB -> b, tupA b -> tupB, tupB a -> tupA where
  -- | Distributes a pure morphism @a -> b@ over every slot of a homogeneous tuple:
  --
  --   \[
  --   \text{mapTupleHom}\;f\;(x_1, \dots, x_k) = (f\;x_1, \dots, f\;x_k)
  --   \]
  --
  --   >>> mapTupleHom (+ 1) (10, 20, 30)
  --   (11, 21, 31)
  mapTupleHom :: (a -> b) -> tupA -> tupB

  -- | Distributes an effectful morphism @a -> m b@ over every slot of a homogeneous
  --   tuple and lifts the enclosing Applicative effect @m@ outward:
  --
  --   \[
  --   \text{traverseTupleHom}\;f\;(x_1, \dots, x_k) = (,,...)\;\langle\$\rangle\;f\;x_1\;\langle*\rangle\;\dots\;\langle*\rangle\;f\;x_k
  --   \]
  --
  --   >>> traverseTupleHom (\x -> if x > 0 then Just (x * 2) else Nothing) (1, 2, 3)
  --   Just (2, 4, 6)
  traverseTupleHom :: Applicative m => (a -> m b) -> tupA -> m tupB

-- | Homogeneous 2-tuple instance.
instance TupleHom (a, a) (b, b) a b where
  mapTupleHom f = uncurryFlat (onN @2 f (,))
  traverseTupleHom f = uncurryFlat (onMN @2 f (,))
  {-# INLINE mapTupleHom #-}
  {-# INLINE traverseTupleHom #-}

-- | Homogeneous 3-tuple instance.
instance TupleHom (a, a, a) (b, b, b) a b where
  mapTupleHom f = uncurryFlat (onN @3 f (,,))
  traverseTupleHom f = uncurryFlat (onMN @3 f (,,))
  {-# INLINE mapTupleHom #-}
  {-# INLINE traverseTupleHom #-}

-- | Homogeneous 4-tuple instance.
instance TupleHom (a, a, a, a) (b, b, b, b) a b where
  mapTupleHom f = uncurryFlat (onN @4 f (,,,))
  traverseTupleHom f = uncurryFlat (onMN @4 f (,,,))
  {-# INLINE mapTupleHom #-}
  {-# INLINE traverseTupleHom #-}

-- | Homogeneous 5-tuple instance.
instance TupleHom (a, a, a, a, a) (b, b, b, b, b) a b where
  mapTupleHom f = uncurryFlat (onN @5 f (,,,,))
  traverseTupleHom f = uncurryFlat (onMN @5 f (,,,,))
  {-# INLINE mapTupleHom #-}
  {-# INLINE traverseTupleHom #-}

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Permute
-- Description: Arbitrary curried function argument permutations via iterated Yank
--
-- Enables reordering curried function arguments arbitrarily according to a type-level
-- permutation list, without tuple-size limits or type-directed ambiguity.
module Gongju.Permute
  ( -- * Type Families
    Adjust
  , MapAdjust
  , MapToPeano
    -- * Arbitrary Permutation
  , Permute(..)
  , permute
  ) where

import GHC.TypeLits (Nat)
import Gongju.Peano (Peano(..), ToPeano)
import Gongju.Positional (Yank(..))

{- Note [Iterated Yank Index Adjustment]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-iterated-yank-adjustment]
Arbitrary argument permutation (e.g. taking f :: a -> b -> c -> d -> r and producing
c -> a -> d -> b -> r via @'[2, 0, 3, 1]) is achieved by decomposing the permutation
into sequential 'Yank' operations.

When an argument at index `p` is pulled to position 0:
  1. Any remaining original target index `i > p` shifts down by 1 in the residual function.
  2. Any remaining original target index `i < p` retains its relative position.

The closed type family 'Adjust' recalculates remaining indices at each inductive step,
and 'Permute' recurses over the updated index list. This provides:
  - Zero tuple size limits (functions of arity 10, 20, 50 can be reordered).
  - Immunity to duplicate types (e.g. Int -> Int -> Int -> r).
  - Support for partial permutations (arguments not mentioned in the permutation list
    remain in their original relative positions at the tail).
-}

-- | Recalculate index @i@ after an element at position @picked@ has been removed.
--
-- See Note [Iterated Yank Index Adjustment] [ref:note-iterated-yank-adjustment].
type family Adjust (picked :: Peano) (i :: Peano) :: Peano where
  Adjust 'Z     ('S i) = i
  Adjust ('S p) ('S i) = 'S (Adjust p i)
  Adjust _      i      = i

-- | Map 'Adjust' over a type-level list of Peano indices.
type family MapAdjust (p :: Peano) (ps :: [Peano]) :: [Peano] where
  MapAdjust _ '[]       = '[]
  MapAdjust p (i ': is) = Adjust p i ': MapAdjust p is

-- | Convert a type-level list of 'Nat' indices to inductive 'Peano' numbers.
type family MapToPeano (ns :: [Nat]) :: [Peano] where
  MapToPeano '[]       = '[]
  MapToPeano (n ': ns) = ToPeano n ': MapToPeano ns

-- | Inductive class computing the permutation of curried function arguments.
class Permute (ps :: [Peano]) f g | ps f -> g where
  -- | Internal worker for executing iterated permutation.
  permute' :: f -> g

instance Permute '[] f f where
  permute' = id
  {-# INLINE permute' #-}

instance (Yank p f arg rest, Permute (MapAdjust p ps) rest rest')
  => Permute (p ': ps) f (arg -> rest') where
  permute' f arg = permute' @(MapAdjust p ps) (yank' @p f arg)
  {-# INLINE permute' #-}

-- | Reorder the arguments of a curried function according to a 0-indexed list of 'Nat' positions.
--
-- Example:
--
-- >>> let f x y z = (x, y, z)
-- >>> permute @'[2, 0, 1] f 3 1 2
-- (1, 2, 3)
permute :: forall (ns :: [Nat]) f g. Permute (MapToPeano ns) f g => f -> g
permute = permute' @(MapToPeano ns)
{-# INLINE permute #-}

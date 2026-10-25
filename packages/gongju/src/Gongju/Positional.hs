{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
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
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Module: Gongju.Positional
-- Description: Guarded arrow unification and positional combinators (Yank, Shove, Twist)
--
-- Provides inductive combinators for manipulating curried function arguments by position:
-- pulling arguments to the front (Yank), pushing arguments deeper (Shove), and swapping
-- adjacent arguments (Twist), accompanied by guarded error messages for arity mismatches.
module Gongju.Positional
  ( -- * Guarded Arrow Unification
    CheckArrow
  , ExpectArrow
    -- * Yank (Pull to Front)
  , Yank(..)
  , slipr
  , yank
    -- * Shove (Push Deeper)
  , Shove(..)
  , slipl
  , shove
    -- * Twist (Adjacent Swap)
  , Twist(..)
  , twist
  ) where

import Data.Kind (Constraint, Type)
import GHC.TypeLits
  ( ErrorMessage (ShowType, Text, (:$$:), (:<>:))
  , Nat
  , Symbol
  , TypeError
  )
import Gongju.Peano (Peano(..), ToPeano)

{- Note [Positional Curried Arrow Manipulation]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-positional-arrow-manipulation]
Manipulating the positional arguments of curried functions (a0 -> a1 -> ... -> r) is
conventionally approached by either:
  1. Converting to an n-tuple via 'Generics.SOP' / 'tuple-sop', which requires finite
     tuple instances and loses bidirectional type inference.
  2. Generating dozens of ad-hoc permutations via Template Haskell.

Gongju manipulates curried function arrows directly in place using three fundamental
primitives:
  1. 'Yank' ('slipr'): Pulls the n-th argument (0-indexed) to position 0, shifting
     intervening arguments [0 .. n-1] one slot to the right.
  2. 'Shove' ('slipl'): Pushes argument 0 into depth n, shifting intervening arguments
     [1 .. n] one slot to the left.
  3. 'Twist' ('twist'): Transposes adjacent arguments at depth n and n+1.

Furthermore, 'CheckArrow' and 'ExpectArrow' provide compile-time guard rails that report
clear, descriptive custom type errors when arity boundaries are exceeded.
-}

-- | Guard family asserting that type @f@ is a function arrow @(a -> b)@.
type family CheckArrow (ctx :: Symbol) (f :: Type) :: Constraint where
  CheckArrow _ (_ -> _) = ()
  CheckArrow ctx nonFn =
    TypeError
      ( 'Text "• [" :<>: 'Text ctx :<>: 'Text "] Arity / Index Mismatch:"
      ':$$: 'Text "  Expected a function (a -> r), but reached: " :<>: 'ShowType nonFn
      )

-- | Constraint requiring @f@ to unify with @(a -> r)@ with diagnostic context @ctx@.
class (CheckArrow ctx f, f ~ (a -> r)) => ExpectArrow (ctx :: Symbol) f a r
instance (CheckArrow ctx f, f ~ (a -> r)) => ExpectArrow ctx f a r

-- | Pull the @n@-th curried argument (0-indexed) to the front position.
--
-- See Note [Positional Curried Arrow Manipulation] [ref:note-positional-arrow-manipulation].
class Yank (n :: Peano) f target rest | n f -> target rest where
  -- | Internal worker for pulling the @n@-th argument forward.
  yank' :: f -> target -> rest

instance ExpectArrow "Yank" (a -> r) a r => Yank 'Z (a -> r) a r where
  yank' f target = f target
  {-# INLINE yank' #-}

instance (ExpectArrow "Yank" (a -> r) a r, Yank n r target rest')
  => Yank ('S n) (a -> r) target (a -> rest') where
  yank' f target a = yank' @n (f a) target
  {-# INLINE yank' #-}

-- | Pull the @n@-th argument (0-indexed) to position 0.
--
-- Equivalent to @slipr@ in 'composition-extra'.
slipr :: forall (n :: Nat) f target rest. Yank (ToPeano n) f target rest => f -> target -> rest
slipr = yank' @(ToPeano n)
{-# INLINE slipr #-}

-- | User-facing synonym for 'slipr': pulls the @n@-th argument (0-indexed) to position 0.
yank :: forall (n :: Nat) f target rest. Yank (ToPeano n) f target rest => f -> target -> rest
yank = yank' @(ToPeano n)
{-# INLINE yank #-}

-- | Push the 0-th argument into position @n@, shifting arguments 1 through @n@ to the left.
class Shove (n :: Peano) a rest f | n a rest -> f, n f -> a rest where
  -- | Internal worker for pushing the head argument deeper.
  shove' :: (a -> rest) -> f

instance Shove 'Z a r (a -> r) where
  shove' = id
  {-# INLINE shove' #-}

instance Shove n a rest r => Shove ('S n) a (b -> rest) (b -> r) where
  shove' f b = shove' @n (`f` b)
  {-# INLINE shove' #-}

-- | Push the 0-th argument into position @n@.
--
-- Equivalent to @slipl@ in 'composition-extra'.
slipl :: forall (n :: Nat) a rest f. Shove (ToPeano n) a rest f => (a -> rest) -> f
slipl = shove' @(ToPeano n)
{-# INLINE slipl #-}

-- | User-facing synonym for 'slipl': pushes the 0-th argument into position @n@.
shove :: forall (n :: Nat) a rest f. Shove (ToPeano n) a rest f => (a -> rest) -> f
shove = shove' @(ToPeano n)
{-# INLINE shove #-}

-- | Swap adjacent arguments at depth @n@ and @n + 1@.
class Twist (n :: Peano) f g | n f -> g, n g -> f where
  -- | Internal worker for transposing adjacent arguments.
  twist' :: f -> g

instance Twist 'Z (a -> b -> r) (b -> a -> r) where
  twist' = flip
  {-# INLINE twist' #-}

instance Twist n r r' => Twist ('S n) (a -> r) (a -> r') where
  twist' f a = twist' @n (f a)
  {-# INLINE twist' #-}

-- | Swap adjacent arguments at depth @n@ and @n + 1@.
twist :: forall (n :: Nat) f g. Twist (ToPeano n) f g => f -> g
twist = twist' @(ToPeano n)
{-# INLINE twist #-}

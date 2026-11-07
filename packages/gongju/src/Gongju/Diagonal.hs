{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Diagonal
-- Description: Homogeneous arity distribution, diagonalization, and variadic zipping
--
-- This module implements type-level arity distribution combinators ('onN', 'diagN')
-- and effectful applicative lifting ('onMN', 'diagMN') over @n@ homogeneous arguments,
-- as well as variadic zipping ('zipWithN') for arbitrary zippable containers ('Zippy').
--
-- = Architectural Context
--
-- Per Note [Gongju Combinator Taxonomy] [ref:note-gongju-combinators], distributing
-- unary or effectful functions across multi-argument curried functions or data
-- constructors often leads to bespoke per-arity combinators (@on2@, @on3@, @dup@, @dup3@).
-- 'Gongju.Diagonal' parameterizes this pattern by a type-level Peano number or 'Nat',
-- providing a zero-cost abstraction that collapses along diagonals and lifts Applicative
-- effects outward automatically.
--
-- == Invariants & Guarantees
--
-- 1. __Zero-Cost Inlining:__ All recursive Peano steps are marked with @{-# INLINE #-}@
--    and fully unroll at compile-time under GHC optimization.
-- 2. __Morphism Distribution Law:__ For any unary morphism \(f: A \to B\) and
--    \(g: B \to \dots \to B \to R\):
--    \[
--    \text{onN } f \; g \; x_1 \dots x_n = g \; (f \; x_1) \dots (f \; x_n)
--    \]
-- 3. __Diagonalization Law:__
--    \[
--    \text{diagN } f \; g \; x = g \; (f \; x) \dots (f \; x)
--    \]
--
-- = Worked Examples
--
-- >>> onN @2 (* 10) (,) 3 4
-- (30, 40)
--
-- >>> onN @3 show (,,) 1 2 3
-- ("1", "2", "3")
--
-- >>> diagN @2 (+) 5
-- 10
--
-- >>> diagN @3 (,,) "sky"
-- ("sky", "sky", "sky")
--
-- >>> zipWithN @3 (,,) [1, 2] ['a', 'b'] [True, False]
-- [(1, 'a', True), (2, 'b', False)]
module Gongju.Diagonal
  ( -- * 1. Homogeneous Arity Distribution & Diagonal (`onN`, `diagN`)
    HomArity (..)
  , onN
  , diagN
    -- * 2. Applicative/Monadic Outward Lifting over Arity `n` (`onMN`, `diagMN`)
  , HomArityM (..)
  , onMN
  , diagMN
    -- * 3. Generalised Arity-`n` Zipping (`Zippy`, `ZipArity`, `zipWithN`)
  , ZipContainer (..)
  , Zippy (..)
  , ZipArity (..)
  , zipWithN
  ) where

import Control.Applicative (ZipList (..))
import Data.Kind (Type)
import Data.List.NonEmpty (NonEmpty (..))
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import GHC.TypeNats (Nat)

import Gongju.Core (Peano (..), ToPeano)

{- Note [Gongju Combinator Taxonomy]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-gongju-combinators]
Distributing unary or effectful functions across multi-argument curried functions or data
constructors often leads to bespoke per-arity combinators (on2, on3, dup, dup3).
Gongju parameterizes this pattern by a type-level Peano number or Nat, providing a
zero-cost abstraction that collapses along diagonals and lifts Applicative effects outward automatically.
-}

--------------------------------------------------------------------------------
-- 1. Pure Homogeneous Arity Distribution (`onN`) & Diagonal (`diagN`)
--------------------------------------------------------------------------------

-- | Distributes a unary morphism @a -> b@ across @n@ homogeneous arguments of
--   a curried function or data constructor @b -> ... -> b -> r@, and collapses
--   it along the diagonal @a -> r@.
class HomArity (n :: Peano) a b r fnB fnA
  | n fnB a b -> r fnA
  , n fnA a b -> r fnB
  , n a b r -> fnB fnA
  where
  -- | Pre-compose @a -> b@ onto all @n@ arguments of @fnB@.
  onPeano :: (a -> b) -> fnB -> fnA

  -- | Diagonalize @fnB@ by feeding @f x@ into all @n@ argument slots.
  diagPeano :: (a -> b) -> fnB -> (a -> r)

-- | Base case: 0 arguments to distribute.
instance HomArity 'Z a b r r r where
  onPeano _ r = r
  diagPeano _ r _ = r
  {-# INLINE onPeano #-}
  {-# INLINE diagPeano #-}

-- | Inductive step: distributes @f@ over argument 1, then recurses on tail.
instance HomArity n a b r fnB fnA
      => HomArity ('S n) a b r (b -> fnB) (a -> fnA) where
  onPeano f g x = onPeano @n f (g (f x))
  diagPeano f g x = diagPeano @n f (g (f x)) x
  {-# INLINE onPeano #-}
  {-# INLINE diagPeano #-}

-- | Ergonomic @Nat@-indexed wrapper for 'onPeano'.
--
--   >>> onN @2 (* 10) (,) 3 4
--   (30, 40)
--
--   >>> onN @3 show (,,) 1 2 3
--   ("1", "2", "3")
{-# INLINE onN #-}
onN :: forall (n :: Nat) a b r fnB fnA.
       HomArity (ToPeano n) a b r fnB fnA
    => (a -> b) -> fnB -> fnA
onN = onPeano @(ToPeano n)

-- | Ergonomic @Nat@-indexed diagonalization (replaces per-arity @dup@).
--
--   >>> diagN @2 (+) 5
--   10
--
--   >>> diagN @3 (,,) "sky"
--   ("sky", "sky", "sky")
{-# INLINE diagN #-}
diagN :: forall (n :: Nat) a b r fnB fnA.
         HomArity (ToPeano n) a b r fnB fnA
      => (a -> b) -> fnB -> (a -> r)
diagN = diagPeano @(ToPeano n)

--------------------------------------------------------------------------------
-- 2. Applicative / Monadic Outward Lifting Over Arity `n` (`onMN`, `diagMN`)
--------------------------------------------------------------------------------

-- | Distributes an effectful function @a -> m b@ across @n@ arguments of a
--   pure constructor/function @b -> ... -> b -> r@, automatically lifting the
--   effect @m@ outward to produce @a -> ... -> a -> m r@.
class HomArityM (n :: Peano) (m :: Type -> Type) a b r fnB fnA
  | n m fnB a b -> r fnA
  , n m a b r -> fnB fnA
  where
  -- | Core inductive worker for 'onMN'.
  onMPeano :: Applicative m => (a -> m b) -> m fnB -> fnA

  -- | Core inductive worker for 'diagMN'.
  diagMPeano :: Applicative m => (a -> m b) -> m fnB -> (a -> m r)

-- | Base case: 0 arguments to lift.
instance HomArityM 'Z m a b r r (m r) where
  onMPeano _ mr = mr
  diagMPeano _ mr _ = mr
  {-# INLINE onMPeano #-}
  {-# INLINE diagMPeano #-}

-- | Inductive step: applies effectful argument via @(<*>)@ and recurses.
instance HomArityM n m a b r fnB fnA
      => HomArityM ('S n) m a b r (b -> fnB) (a -> fnA) where
  onMPeano f mg x = onMPeano @n f (mg <*> f x)
  diagMPeano f mg x = diagMPeano @n f (mg <*> f x) x
  {-# INLINE onMPeano #-}
  {-# INLINE diagMPeano #-}

-- | Distributes @f :: a -> m b@ across @n@ arguments of @g :: b -> ... -> b -> r@
--   and lifts @m@ outward to the result: @a -> ... -> a -> m r@.
--
--   >>> onMN @2 (\x -> Just (x + 1)) (,) 10 20
--   Just (11, 21)
{-# INLINE onMN #-}
onMN :: forall (n :: Nat) m a b r fnB fnA.
        (Applicative m, HomArityM (ToPeano n) m a b r fnB fnA)
     => (a -> m b) -> fnB -> fnA
onMN f g = onMPeano @(ToPeano n) f (pure g)

-- | Evaluates @f x@ @n@ times and lifts the effect @m@ outward over @g@.
--
--   >>> diagMN @2 (\x -> [x, -x]) (,) 5
--   [(5,5),(5,-5),(-5,5),(-5,-5)]
{-# INLINE diagMN #-}
diagMN :: forall (n :: Nat) m a b r fnB fnA.
          (Applicative m, HomArityM (ToPeano n) m a b r fnB fnA)
       => (a -> m b) -> fnB -> (a -> m r)
diagMN f g = diagMPeano @(ToPeano n) f (pure g)

--------------------------------------------------------------------------------
-- 3. Generalised Arity-`n` Zipping (`Zippy` & `zipWithN`)
--------------------------------------------------------------------------------

-- | Typeclass for containers supporting positional zipwise application.
class Functor f => ZipContainer f where
  -- | Pure repeater for zip application.
  zipPure :: a -> f a

  -- | Zipwise function application.
  zipAp   :: f (a -> b) -> f a -> f b

-- | Instance for standard list.
instance ZipContainer [] where
  zipPure = repeat
  zipAp   = zipWith ($)
  {-# INLINE zipPure #-}
  {-# INLINE zipAp #-}

-- | Instance for NonEmpty list.
instance ZipContainer NonEmpty where
  zipPure x = x :| repeat x
  zipAp (f :| fs) (x :| xs) = f x :| zipWith ($) fs xs
  {-# INLINE zipPure #-}
  {-# INLINE zipAp #-}

-- | Instance for Sequence.
instance ZipContainer Seq where
  zipPure = error "ZipContainer Seq: zipPure requires bounded target"
  zipAp   = Seq.zipWith ($)
  {-# INLINE zipAp #-}

-- | Instance for Applicative ZipList.
instance ZipContainer ZipList where
  zipPure = pure
  zipAp   = (<*>)
  {-# INLINE zipPure #-}
  {-# INLINE zipAp #-}

-- | Newtype wrapper endowing any 'ZipContainer' with its canonical Applicative instance.
newtype Zippy f a = Zippy { unZippy :: f a }
  deriving newtype (Eq, Ord, Show, Functor, Foldable)

-- | Applicative instance for 'Zippy'.
instance ZipContainer f => Applicative (Zippy f) where
  pure x = Zippy (zipPure x)
  Zippy fs <*> Zippy xs = Zippy (zipAp fs xs)
  {-# INLINE pure #-}
  {-# INLINE (<*>) #-}

-- | Inductively lifts an @n@-ary pure function @a1 -> ... -> an -> r@ into an
--   @n@-ary zipping function @f a1 -> ... -> f an -> f r@.
class ZipArity (n :: Peano) (f :: Type -> Type) fn zipFn
  | n f fn -> zipFn
  , n zipFn -> f fn
  where
  -- | Core inductive worker for 'zipWithN'.
  zipPeano :: ZipContainer f => f fn -> zipFn

-- | Base case: 0 remaining arguments.
instance ZipArity 'Z f r (f r) where
  zipPeano = id
  {-# INLINE zipPeano #-}

-- | Inductive step: consumes next container and recurses.
instance ZipArity n f fn zipFn
      => ZipArity ('S n) f (a -> fn) (f a -> zipFn) where
  zipPeano fs xs = zipPeano @n (zipAp fs xs)
  {-# INLINE zipPeano #-}

-- | Variadic @n@-ary @zipWith@ for any 'ZipContainer' ('[]', 'NonEmpty', etc.).
--
--   >>> zipWithN @3 (,,) [1, 2] ['a', 'b'] [True, False]
--   [(1, 'a', True), (2, 'b', False)]
{-# INLINE zipWithN #-}
zipWithN :: forall (n :: Nat) f fn zipFn.
            (ZipContainer f, ZipArity (ToPeano n) f fn zipFn)
         => fn -> zipFn
zipWithN f = zipPeano @(ToPeano n) (zipPure f)

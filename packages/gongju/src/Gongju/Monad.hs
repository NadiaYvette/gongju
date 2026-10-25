{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Monad
-- Description: Positional Monadic Curried Binding, Multi-Slot Lifting Masks, and Kleisli Arity Chains
--
-- Replaces Template Haskell monadic splices (such as 'Control.Monad.Syntax' in 'composition-extra')
-- with pure type-level Peano induction, bidirectional functional dependencies, and multi-slot
-- monadic lifting masks.
--
-- Provides:
-- * Two-phase positional monadic binding ('BindAfter', 'BindPos', 'bindPos', 'bindAt').
-- * Classic monadic binding operators for curried functions:
--   * Tail binds: '(==<<)', '(===<<)', '(====<<)' and flips '(>>==)', '(>>===)', '(>>====)'.
--   * Interior binds: '(=.=<<)', '(==.<<)', '(=..<<)' and flips '(>>=.=)', '(>>.==)', '(>>..=)'.
-- * Multi-slot monadic lifting masks ('LiftMask', 'liftMask', 'ArgMode(Pure, Monadic)').
-- * Arity-indexed Kleisli composition and pure lifting ('liftPureN', 'bindKleisliN', '(<=<.)', '(<=<..)', '(.>=>)', '(..>=>)').
module Gongju.Monad
  ( -- * Two-Phase Positional Monadic Binding
    BindAfter (..)
  , BindPos (..)
  , bindPos
  , bindAt
    -- * Tail Monadic Binding Operators (after = 0)
  , (==<<)
  , (===<<)
  , (====<<)
  , (>>==)
  , (>>===)
  , (>>====)
    -- * Interior Monadic Binding Operators (after > 0)
  , (=.=<<)
  , (==.<<)
  , (=..<<)
  , (>>=.=)
  , (>>.==)
  , (>>..=)
    -- * Multi-Slot Monadic Lifting Masks
  , ArgMode (..)
  , PureArg
  , MonadicArg
  , PArg
  , MArg
  , LiftMask (..)
    -- * Arity-Indexed Kleisli Composition & Pure Lifting
  , liftPureN
  , bindKleisliN
  , (<=<.)
  , (<=<..)
  , (.>=>)
  , (..>=>)
  ) where

import Data.Kind (Type)
import GHC.TypeLits (Nat)
import Gongju.Composition (ComposeN (..), compN)
import Gongju.Peano (Length, Peano (..), ToPeano)

{- Note [Positional Monadic Curried Binding]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-positional-monadic-binding]
In multi-argument Haskell functions returning a monadic result:
  @f :: a -> b -> c -> m d@
one often wishes to bind a monadic value @m b@ into an interior or trailing argument
slot while leaving all other pure arguments curried outside.

In libraries relying on Template Haskell splices (such as 'composition-extra'),
separate modules ('Control.Monad.Syntax.Two', '.Three', ..., '.Six') generate fixed
splices for every permutation of argument count and binding position.

Gongju replaces this combinatorial explosion with two-phase structural Peano induction:
  1. 'BindAfter (after :: Peano) (m :: Type -> Type) b f g':
     Floats @after@ trailing pure arguments outside of '(>>=)'.
     When @after = 0@ (@'Z@), the binding reduces to standard monadic bind @mb >>= f@.
     When @after > 0@ (@'S after@), applying @f b@ yields a function @c -> r@, not a
     monadic computation. 'BindAfter' suspends argument @c@, threading it inside the
     continuation @\b -> f b c@ before executing @mb >>= ...@.
  2. 'BindPos (before :: Peano) (after :: Peano) (m :: Type -> Type) b f g':
     Skips @before@ leading pure arguments by peeling them off with lambda abstraction,
     then delegates to 'BindAfter' to float the remaining @after@ trailing arguments.

Bidirectional functional dependencies:
  - @before after f -> b m g@: Determines the target argument @b@, monad @m@, and result @g@
    uniquely from the input function @f@ and position coordinates.
  - @before after m b g -> f@: Reconstructs the original curried function type @f@ when the
    bound type and result type are specified.
-}

-- ---------------------------------------------------------------------------
-- 1. Two-Phase Positional Monadic Binding (BindAfter & BindPos)
-- ---------------------------------------------------------------------------

-- | Phase 1: Float @after@ trailing pure arguments outside '(>>=)'.
--
-- See Note [Positional Monadic Curried Binding] [ref:note-positional-monadic-binding].
class Monad m => BindAfter (after :: Peano) (m :: Type -> Type) b f g | after f -> m g, after m b g -> f where
  -- | Internal inductive worker floating trailing pure arguments outside '(>>=)'.
  bindAfter' :: (b -> f) -> m b -> g

instance Monad m => BindAfter 'Z m b (m r) (m r) where
  bindAfter' f mb = mb >>= f
  {-# INLINE bindAfter' #-}

instance BindAfter after m b r r' => BindAfter ('S after) m b (c -> r) (c -> r') where
  bindAfter' f mb c = bindAfter' @after (`f` c) mb
  {-# INLINE bindAfter' #-}

-- | Phase 2: Skip @before@ leading pure arguments, then hand off to 'BindAfter'.
--
-- See Note [Positional Monadic Curried Binding] [ref:note-positional-monadic-binding].
class Monad m => BindPos (before :: Peano) (after :: Peano) (m :: Type -> Type) b f g | before after f -> b m g, before after m b g -> f where
  -- | Internal inductive worker skipping leading pure arguments.
  bindPos' :: f -> m b -> g

instance BindAfter after m b rest g => BindPos 'Z after m b (b -> rest) g where
  bindPos' f mb = bindAfter' @after f mb
  {-# INLINE bindPos' #-}

instance BindPos before after m b r r' => BindPos ('S before) after m b (a -> r) (a -> r') where
  bindPos' f mb a = bindPos' @before @after (f a) mb
  {-# INLINE bindPos' #-}

-- | User-facing positional monadic bind parameterized by visible 'Nat' literals:
-- @before@ (leading pure arguments to skip) and @after@ (trailing pure arguments to float).
--
-- Examples:
--
-- >>> let add3 x y z = pure (x + y + z) :: Maybe Int
-- >>> bindPos @1 @1 add3 (Just 20) 1 3
-- Just 24
-- >>> bindPos @0 @2 add3 (Just 10) 2 3
-- Just 15
bindPos :: forall (before :: Nat) (after :: Nat) m b f g.
  BindPos (ToPeano before) (ToPeano after) m b f g => f -> m b -> g
bindPos = bindPos' @(ToPeano before) @(ToPeano after)
{-# INLINE bindPos #-}

-- | Top-level positional monadic bind for argument index @n@ (0-indexed) where all
-- subsequent arguments have already been applied or are pure (@after = 0@).
--
-- @bindAt \@0@ corresponds to '(=<<)'.
-- @bindAt \@1@ corresponds to '(==<<)'.
-- @bindAt \@2@ corresponds to '(===<<)'.
--
-- Example:
--
-- >>> let f x y = pure (x * y) :: Maybe Int
-- >>> bindAt @1 f (Just 7) 6
-- Just 42
bindAt :: forall (n :: Nat) m b f g.
  BindPos (ToPeano n) 'Z m b f g => f -> m b -> g
bindAt = bindPos' @(ToPeano n) @'Z
{-# INLINE bindAt #-}

-- ---------------------------------------------------------------------------
-- 2. Tail Monadic Binding Operators (after = 0)
-- ---------------------------------------------------------------------------

-- | Infix positional monadic bind at argument slot 1 (@after = 0@).
-- Binds 'm b' into '(a -> b -> m c)', returning 'a -> m c'.
infixr 1 ==<<
(==<<) :: BindPos ('S 'Z) 'Z m b f g => f -> m b -> g
(==<<) = bindPos' @('S 'Z) @'Z
{-# INLINE (==<<) #-}

-- | Infix positional monadic bind at argument slot 2 (@after = 0@).
-- Binds 'm c' into '(a -> b -> c -> m d)', returning 'a -> b -> m d'.
infixr 1 ===<<
(===<<) :: BindPos ('S ('S 'Z)) 'Z m b f g => f -> m b -> g
(===<<) = bindPos' @('S ('S 'Z)) @'Z
{-# INLINE (===<<) #-}

-- | Infix positional monadic bind at argument slot 3 (@after = 0@).
-- Binds 'm d' into '(a -> b -> c -> d -> m e)', returning 'a -> b -> c -> m e'.
infixr 1 ====<<
(====<<) :: BindPos ('S ('S ('S 'Z))) 'Z m b f g => f -> m b -> g
(====<<) = bindPos' @('S ('S ('S 'Z))) @'Z
{-# INLINE (====<<) #-}

-- | Forward positional monadic bind at argument slot 1: @mb >>== f = f ==<< mb@.
infixl 1 >>==
(>>==) :: BindPos ('S 'Z) 'Z m b f g => m b -> f -> g
(>>==) = flip (==<<)
{-# INLINE (>>==) #-}

-- | Forward positional monadic bind at argument slot 2: @mc >>=== f = f ===<< mc@.
infixl 1 >>===
(>>===) :: BindPos ('S ('S 'Z)) 'Z m b f g => m b -> f -> g
(>>===) = flip (===<<)
{-# INLINE (>>===) #-}

-- | Forward positional monadic bind at argument slot 3: @md >>==== f = f ====<< md@.
infixl 1 >>====
(>>====) :: BindPos ('S ('S ('S 'Z))) 'Z m b f g => m b -> f -> g
(>>====) = flip (====<<)
{-# INLINE (>>====) #-}

-- ---------------------------------------------------------------------------
-- 3. Interior Monadic Binding Operators (after > 0)
-- ---------------------------------------------------------------------------

-- | Infix positional monadic bind for 3-argument function at slot 1 (@before = 1, after = 1@).
-- Binds 'm b' into '(a -> b -> c -> m d)', returning 'a -> c -> m d'.
infixr 1 =.=<<
(=.=<<) :: BindPos ('S 'Z) ('S 'Z) m b f g => f -> m b -> g
(=.=<<) = bindPos' @('S 'Z) @('S 'Z)
{-# INLINE (=.=<<) #-}

-- | Infix positional monadic bind for 3-argument function at slot 0 (@before = 0, after = 2@).
-- Binds 'm a' into '(a -> b -> c -> m d)', returning 'b -> c -> m d'.
infixr 1 ==.<<, =..<<
(==.<<), (=..<<) :: BindPos 'Z ('S ('S 'Z)) m b f g => f -> m b -> g
(==.<<) = bindPos' @'Z @('S ('S 'Z))
(=..<<) = bindPos' @'Z @('S ('S 'Z))
{-# INLINE (==.<<) #-}
{-# INLINE (=..<<) #-}

-- | Forward positional monadic bind for 3-argument function at slot 1: @mb >>=.= f = f =.=<< mb@.
infixl 1 >>=.=
(>>=.=) :: BindPos ('S 'Z) ('S 'Z) m b f g => m b -> f -> g
(>>=.=) = flip (=.=<<)
{-# INLINE (>>=.=) #-}

-- | Forward positional monadic bind for 3-argument function at slot 0: @ma >>.== f = f ==.<< ma@.
infixl 1 >>.==, >>..=
(>>.==), (>>..=) :: BindPos 'Z ('S ('S 'Z)) m b f g => m b -> f -> g
(>>.==) = flip (==.<<)
(>>..=) = flip (=..<<)
{-# INLINE (>>.==) #-}
{-# INLINE (>>..=) #-}

{- Note [Multi-Slot Monadic Lifting Masks]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-multislot-monadic-masks]
In 'Control.Monad.Syntax', operators allow binding only a single monadic argument at a time.
With a promoted two-element kind 'ArgMode = Pure | Monadic', callers can lift any arbitrary
subset of a curried function's arguments into 'Monad m' simultaneously in a single pass.

Given @f :: a -> b -> c -> m d@:
  @liftMask @'[MArg, PArg, MArg] f :: m a -> b -> m c -> m d@

The transformation proceeds inductively on the type-level list @mask :: [ArgMode]@:
  1. Base case @'[]@: The return type must already be of the form @m r@.
  2. Pure step @'Pure ': ms@: Leaves the current argument pure @(a -> ...)@ and recurses on @ms@.
  3. Monadic step @'Monadic ': ms@: Transforms @a@ into @m a@, recurses on @ms@ producing
     transformed tail @r'@, and uses 'BindAfter (Length ms)' to float all trailing arguments
     outside the bind. Monadic effects are sequenced strictly from left to right.
-}

-- ---------------------------------------------------------------------------
-- 4. Multi-Slot Monadic Lifting Masks (LiftMask)
-- ---------------------------------------------------------------------------

-- | Argument lifting mode for multi-slot monadic masks.
-- 'Pure keeps the curried argument as pure @a@.
-- 'Monadic lifts the argument from @a@ to @m a@ and sequences its monadic effect.
data ArgMode
  = Pure     -- ^ Keep the curried argument pure.
  | Monadic  -- ^ Lift the curried argument into the monad @m@.
  deriving (Eq, Ord, Show, Enum, Bounded)

-- | Convenient type synonyms for mask annotations.
type PureArg = 'Pure
type MonadicArg = 'Monadic
type PArg = 'Pure
type MArg = 'Monadic

-- | Multi-slot monadic lifting mask.
--
-- Transforms a curried function @f@ into @g@ by lifting arguments marked 'Monadic
-- into the monad @m@ while preserving pure arguments marked 'Pure'.
--
-- See Note [Multi-Slot Monadic Lifting Masks] [ref:note-multislot-monadic-masks].
class Monad m => LiftMask (mask :: [ArgMode]) (m :: Type -> Type) f g | mask f -> m g, mask m g -> f where
  -- | Lift a curried function according to the type-level mode mask.
  liftMask :: f -> g

instance Monad m => LiftMask '[] m (m r) (m r) where
  liftMask = id
  {-# INLINE liftMask #-}

instance LiftMask ms m r r' => LiftMask ('Pure ': ms) m (a -> r) (a -> r') where
  liftMask f a = liftMask @ms (f a)
  {-# INLINE liftMask #-}

instance (Monad m, BindAfter (Length ms) m a r' g, LiftMask ms m r r')
  => LiftMask ('Monadic ': ms) m (a -> r) (m a -> g) where
  liftMask f ma = bindAfter' @(Length ms) (liftMask @ms . f) ma
  {-# INLINE liftMask #-}

-- ---------------------------------------------------------------------------
-- 5. Arity-Indexed Kleisli Composition & Pure Lifting
-- ---------------------------------------------------------------------------

-- | Lift a pure @n@-ary curried function to produce results inside an 'Applicative' functor.
--
-- Equivalent to @compN \@n pure@.
--
-- Examples:
--
-- >>> liftPureN @1 (+ 1) 5 :: Maybe Int
-- Just 6
-- >>> liftPureN @2 (+) 3 4 :: Maybe Int
-- Just 7
liftPureN :: forall (n :: Nat) m a f g.
  (Applicative m, ComposeN (ToPeano n) a (m a) f g) => f -> g
liftPureN = compN @n pure
{-# INLINE liftPureN #-}

-- | Post-compose a monadic Kleisli arrow @(b -> m c)@ after an @n@-ary curried monadic function
-- @(a1 -> ... -> an -> m b)@.
--
-- Equivalent to @compN \@n (>>= k)@.
--
-- Examples:
--
-- >>> let f x y = Just (x + y)
-- >>> let checkEven z = if even z then Just z else Nothing
-- >>> bindKleisliN @2 checkEven f 2 4
-- Just 6
-- >>> bindKleisliN @2 checkEven f 2 3
-- Nothing
bindKleisliN :: forall (n :: Nat) m b c f g.
  (Monad m, ComposeN (ToPeano n) (m b) (m c) f g) => (b -> m c) -> f -> g
bindKleisliN k = compN @n (>>= k)
{-# INLINE bindKleisliN #-}

-- | Binary Kleisli composition: post-composes @k :: b -> m c@ onto a binary monadic function.
--
-- @(k <=<. f) x y = f x y >>= k@
infixr 1 <=<.
(<=<.) :: (Monad m, ComposeN ('S ('S 'Z)) (m b) (m c) f g) => (b -> m c) -> f -> g
(<=<.) = bindKleisliN @2
{-# INLINE (<=<.) #-}

-- | Ternary Kleisli composition: post-composes @k :: b -> m c@ onto a ternary monadic function.
--
-- @(k <=<.. f) x y z = f x y z >>= k@
infixr 1 <=<..
(<=<..) :: (Monad m, ComposeN ('S ('S ('S 'Z))) (m b) (m c) f g) => (b -> m c) -> f -> g
(<=<..) = bindKleisliN @3
{-# INLINE (<=<..) #-}

-- | Forward binary Kleisli composition: @(f .>=> k) x y = f x y >>= k@.
infixr 1 .>=>
(.>=>) :: (Monad m, ComposeN ('S ('S 'Z)) (m b) (m c) f g) => f -> (b -> m c) -> g
(.>=>) f k = (<=<.) k f
{-# INLINE (.>=>) #-}

-- | Forward ternary Kleisli composition: @(f ..>=> k) x y z = f x y z >>= k@.
infixr 1 ..>=>
(..>=>) :: (Monad m, ComposeN ('S ('S ('S 'Z))) (m b) (m c) f g) => f -> (b -> m c) -> g
(..>=>) f k = (<=<..) k f
{-# INLINE (..>=>) #-}

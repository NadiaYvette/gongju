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
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Contravariant
-- Description: Contravariant Syntax Grids, Positional Pre-Composition, and Alternating Parity Stacks
--
-- Replaces Template Haskell contravariant splices (such as 'composition-extra') with pure
-- type-level Peano induction, bidirectional functional dependencies, and type-safe argument pre-processing.
--
-- Provides:
-- * Positional curried pre-composition ('PrecomposeAt', 'precomposeAt @n', '(-.)', '(-.*)', '(-.**)', '(-.***)').
-- * 2D function splicing grid ('SpliceAt', 'spliceAt @n @m').
-- * Alternating parity contravariant functor mapping ('ContramapN', 'contramapN @n', '(<-$>)', '(<-$$>)', '(<-$$$>)').
-- * Canonical re-exports of 'Contravariant', 'Divisible', and 'Decidable' from 'base'.
module Gongju.Contravariant
  ( -- * Positional Pre-Composition
    PrecomposeAt (..)
  , precomposeAt
  , (-.)
  , (-.*)
  , (-.**)
  , (-.***)
    -- * 2D Function Splicing Grid
  , SpliceAt (..)
  , spliceAt
    -- * Nested Contravariant Mapping (Alternating Parity)
  , ContramapN (..)
  , ContravariantN
  , contramapN
  , (<-$>)
  , (<-$$>)
  , (<-$$$>)
  , (<-$$$$>)
    -- * Re-exported Canonical Classes & Types
  , Contravariant (..)
  , (>$<)
  , Predicate (..)
  , Comparison (..)
  , Equivalence (..)
  , Op (..)
  , Divisible (..)
  , Decidable (..)
  ) where

import Data.Functor.Contravariant
  ( Comparison (..)
  , Contravariant (..)
  , Equivalence (..)
  , Op (..)
  , Predicate (..)
  , (>$<)
  )
import Data.Functor.Contravariant.Divisible
  ( Decidable (..)
  , Divisible (..)
  )
import GHC.TypeLits (Nat)
import Gongju.Composition (ComposeN (..))
import Gongju.Peano (Peano (..), ToPeano)

{- Note [Contravariant Positional Pre-Composition]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-contravariant-precomposition]
Because the function arrow @(->)@ is contravariant in its argument position,
"contravariant function composition" corresponds to pre-composing a transformation
function onto an argument consumed by another function.

In libraries relying on Template Haskell splices (such as 'composition-extra'),
operators proliferate along two distinct axes:
  1. The target argument slot index @n@ of @f@ being pre-composed:
     @(-.)@ at slot 0, @(-.*)@ at slot 1, @(-.**)@ at slot 2, etc.
  2. The arity @m@ of arguments consumed by the pre-composed function @h@:
     @(-.)@ for unary, @(-.:)@ for binary, @(-..:)@ for ternary, etc.

Gongju collapses both axes into two inductively resolved typeclasses:
  * 'PrecomposeAt': Unary pre-composition at positional depth @n@.
  * 'SpliceAt': Full 2D generalization splicing an @m@-ary function into slot @n@.

Full bidirectional functional dependencies are maintained across the grid:
  - @n f -> b@: Determines the target argument type @b@ from slot @n@ and @f@.
  - @n g -> a@: Determines the new argument type @a@ from slot @n@ and @g@.
  - @n a f -> g@: Infers the transformed signature @g@ from input @a@ and @f@.
  - @n b g -> f@: Recovers the original signature @f@ from target @b@ and @g@.
-}

-- ---------------------------------------------------------------------------
-- 1. Positional Pre-Composition (PrecomposeAt)
-- ---------------------------------------------------------------------------

-- | Pre-compose a unary function @(a -> b)@ onto the @n@-th argument (0-indexed) of @f@.
--
-- See Note [Contravariant Positional Pre-Composition] [ref:note-contravariant-precomposition].
class PrecomposeAt (n :: Peano) a b f g | n f -> b, n g -> a, n a f -> g, n b g -> f where
  -- | Internal inductive worker operating on 'Peano' terms.
  precomposeAt' :: (a -> b) -> f -> g

instance PrecomposeAt 'Z a b (b -> r) (a -> r) where
  precomposeAt' h f a = f (h a)
  {-# INLINE precomposeAt' #-}

instance PrecomposeAt n a b r r' => PrecomposeAt ('S n) a b (x -> r) (x -> r') where
  precomposeAt' h f x = precomposeAt' @n h (f x)
  {-# INLINE precomposeAt' #-}

-- | User-facing positional pre-composition parameterized by visible 'Nat' literal @n@.
--
-- Example:
--
-- >>> let add3 x y z = (x + y + z :: Int)
-- >>> precomposeAt @1 (* 10) add3 1 2 3
-- 24
precomposeAt :: forall (n :: Nat) a b f g. PrecomposeAt (ToPeano n) a b f g => (a -> b) -> f -> g
precomposeAt = precomposeAt' @(ToPeano n)
{-# INLINE precomposeAt #-}

-- | Infix pre-composition at argument slot 0: @(h -. f) a = f (h a)@.
infixr 9 -.
(-.) :: PrecomposeAt 'Z a b f g => (a -> b) -> f -> g
(-.) = precomposeAt' @'Z
{-# INLINE (-.) #-}

-- | Infix pre-composition at argument slot 1: @(h -.* f) x a = f x (h a)@.
infixr 9 -.*
(-.*) :: PrecomposeAt ('S 'Z) a b f g => (a -> b) -> f -> g
(-.*) = precomposeAt' @('S 'Z)
{-# INLINE (-.*) #-}

-- | Infix pre-composition at argument slot 2: @(h -.** f) x y a = f x y (h a)@.
infixr 9 -.**
(-.**) :: PrecomposeAt ('S ('S 'Z)) a b f g => (a -> b) -> f -> g
(-.**) = precomposeAt' @('S ('S 'Z))
{-# INLINE (-.**) #-}

-- | Infix pre-composition at argument slot 3: @(h -.*** f) x y z a = f x y z (h a)@.
infixr 9 -.***
(-.***) :: PrecomposeAt ('S ('S ('S 'Z))) a b f g => (a -> b) -> f -> g
(-.***) = precomposeAt' @('S ('S ('S 'Z)))
{-# INLINE (-.***) #-}

-- ---------------------------------------------------------------------------
-- 2. 2D Function Splicing Grid (SpliceAt)
-- ---------------------------------------------------------------------------

-- | Splice an @m@-ary function @h@ directly into the @n@-th argument slot of @f@.
--
-- The resulting function @g@ consumes @n@ arguments, then the @m@ arguments required by @h@,
-- followed by the remaining arguments of @f@.
--
-- See Note [Contravariant Positional Pre-Composition] [ref:note-contravariant-precomposition].
class SpliceAt (n :: Peano) (m :: Peano) h f g | n m h f -> g where
  -- | Internal inductive worker operating on 'Peano' depths.
  spliceAt' :: h -> f -> g

instance ComposeN m d r h g => SpliceAt 'Z m h (d -> r) g where
  spliceAt' h f = composeN' @m f h
  {-# INLINE spliceAt' #-}

instance SpliceAt n m h r r' => SpliceAt ('S n) m h (a -> r) (a -> r') where
  spliceAt' h f a = spliceAt' @n @m h (f a)
  {-# INLINE spliceAt' #-}

-- | User-facing 2D function splicing parameterized by visible 'Nat' literals @n@ (target slot)
-- and @m@ (spliced function arity).
--
-- Example:
--
-- >>> let add3 x y z = (x + y + z :: Int)
-- >>> let mult2 u v = (u * v :: Int)
-- >>> spliceAt @1 @2 mult2 add3 10 3 4 5
-- 27
spliceAt :: forall (n :: Nat) (m :: Nat) h f g. SpliceAt (ToPeano n) (ToPeano m) h f g => h -> f -> g
spliceAt = spliceAt' @(ToPeano n) @(ToPeano m)
{-# INLINE spliceAt #-}

{- Note [Contravariant Functor Alternating Parity]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-contravariant-alternating-parity]
In 'Data.Functor.Contravariant.Syntax' (operators @<-$@, @<-$$@, @<-$$$@, ...),
mapping a transformation function @(a -> b)@ through nested 'Contravariant' functor layers
introduces an alternating parity flip:
  - 1 layer (@1):  @(a -> b) -> f b -> f a@ (contravariant: reverses arrow)
  - 2 layers (@2): @(a -> b) -> f (g a) -> f (g b)@ (covariant: two reversals cancel!)
  - 3 layers (@3): @(a -> b) -> f (g (h b)) -> f (g (h a))@ (contravariant again)

With Peano induction, swapping @s@ and @t@ in the recursive constraint:
  @instance (Contravariant f, ContramapN n a b t s) => ContramapN ('S n) a b (f s) (f t)@
tracks this variance reversal automatically.

Furthermore, the pair of bidirectional functional dependencies:
  @n a b s -> t, n a b t -> s@
mutually inductive-check each other across the parity swap, preserving full type inference.
-}

-- ---------------------------------------------------------------------------
-- 3. Nested Contravariant Functor Mapping (Alternating Parity)
-- ---------------------------------------------------------------------------

-- | Map a transformation through @n@ nested 'Contravariant' functor layers with alternating parity.
--
-- See Note [Contravariant Functor Alternating Parity] [ref:note-contravariant-alternating-parity].
class ContramapN (n :: Peano) a b s t | n s t -> a b, n a b s -> t, n a b t -> s where
  -- | Internal inductive worker operating on 'Peano' depth.
  contramapN' :: (a -> b) -> s -> t

instance ContramapN 'Z a b a b where
  contramapN' f = f
  {-# INLINE contramapN' #-}

instance (Contravariant f, ContramapN n a b t s) => ContramapN ('S n) a b (f s) (f t) where
  contramapN' f = contramap (contramapN' @n f)
  {-# INLINE contramapN' #-}

-- | User-facing constraint synonym parameterized by visible 'Nat' depth @n@.
type ContravariantN (n :: Nat) a b s t = ContramapN (ToPeano n) a b s t

-- | Map a transformation through @n@ nested 'Contravariant' functor layers.
--
-- Examples:
--
-- >>> let p = Predicate (> 0) :: Predicate Int
-- >>> let p' = contramapN @1 (* 2) p
-- >>> getPredicate p' 5
-- True
contramapN :: forall (n :: Nat) a b s t. ContramapN (ToPeano n) a b s t => (a -> b) -> s -> t
contramapN = contramapN' @(ToPeano n)
{-# INLINE contramapN #-}

-- | Infix contravariant mapping at depth 1 (equivalent to 'contramap' / '(>$<)').
infixr 4 <-$>
(<-$>) :: ContramapN ('S 'Z) a b s t => (a -> b) -> s -> t
(<-$>) = contramapN' @('S 'Z)
{-# INLINE (<-$>) #-}

-- | Infix contravariant mapping at depth 2 (covariant due to parity cancellation).
infixr 4 <-$$>
(<-$$>) :: ContramapN ('S ('S 'Z)) a b s t => (a -> b) -> s -> t
(<-$$>) = contramapN' @('S ('S 'Z))
{-# INLINE (<-$$>) #-}

-- | Infix contravariant mapping at depth 3 (contravariant).
infixr 4 <-$$$>
(<-$$$>) :: ContramapN ('S ('S ('S 'Z))) a b s t => (a -> b) -> s -> t
(<-$$$>) = contramapN' @('S ('S ('S 'Z)))
{-# INLINE (<-$$$>) #-}

-- | Infix contravariant mapping at depth 4 (covariant).
infixr 4 <-$$$$>
(<-$$$$>) :: ContramapN ('S ('S ('S ('S 'Z)))) a b s t => (a -> b) -> s -> t
(<-$$$$>) = contramapN' @('S ('S ('S ('S 'Z))))
{-# INLINE (<-$$$$>) #-}

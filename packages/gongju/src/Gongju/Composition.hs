{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Composition
-- Description: Variadic arity composition and nested functor mapping
--
-- Provides inductive typeclasses for composing curried functions across arbitrary
-- arity barriers and mapping functions across nested functor layers without
-- Template Haskell splices.
module Gongju.Composition
  ( -- * Variadic Arity Composition
    ComposeN(..)
  , compN
    -- * Nested Functor Mapping
  , FmapN(..)
  , fmapN
  ) where

import GHC.TypeLits (Nat)
import Gongju.Peano (Peano(..), ToPeano)

{- Note [Variadic Composition Bidirectional Fundeps]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-variadic-composition-fundeps]
Template Haskell composition libraries (such as 'composition-extra') generate static
operators for fixed arities ((.:), (..:), (...:)). Beyond bloating code size, Template
Haskell splices cannot be abstracted over dynamically in type-level pipelines.

Gongju replaces these splices with an inductive typeclass 'ComposeN', indexed by the
Peano depth @n@ representing the number of arguments consumed by function @g@ before
feeding its terminal result to @f@.

Crucially, bidirectional functional dependencies are maintained:
  @n b c g -> f@: Propagates input function types forward to determine composite function type.
  @n f -> c@: Propagates expected output type backward into the composite structure.
  @n f b -> g@: Infers intermediate argument shapes under polymorphic unification.
-}

-- | Inductive arity composition class parameterized over Peano depth @n@.
--
-- See Note [Variadic Composition Bidirectional Fundeps] [ref:note-variadic-composition-fundeps].
class ComposeN (n :: Peano) b c g f | n b c g -> f, n f -> c, n f b -> g where
  -- | Internal composition worker operating on inductive 'Peano' terms.
  composeN' :: (b -> c) -> g -> f

instance ComposeN 'Z b c b c where
  composeN' f x = f x

instance ComposeN n b c r r' => ComposeN ('S n) b c (a -> r) (a -> r') where
  composeN' f g a = composeN' @n f (g a)

-- | Compose a unary function @(b -> c)@ with a curried function consuming @n@ arguments.
--
-- Examples:
--
-- @
-- compN @1 == (.)
-- compN @2 == (.:)
-- compN @3 == (..:)
-- @
compN :: forall (n :: Nat) b c g f. ComposeN (ToPeano n) b c g f => (b -> c) -> g -> f
compN = composeN' @(ToPeano n)

-- | Inductive nested functor mapping class parameterized over nesting depth @n@.
class FmapN (n :: Peano) a b s t | n a b s -> t, n s t -> a b where
  -- | Internal functor mapping worker operating on inductive 'Peano' terms.
  fmapN' :: (a -> b) -> s -> t

instance FmapN 'Z a b a b where
  fmapN' f = f

instance (Functor f, FmapN n a b s t) => FmapN ('S n) a b (f s) (f t) where
  fmapN' f = fmap (fmapN' @n f)

-- | Map a transformation @(a -> b)@ through @n@ nested 'Functor' layers.
--
-- Examples:
--
-- @
-- fmapN @1 == fmap   -- (<$>)
-- fmapN @2 == fmap . fmap
-- fmapN @3 == fmap . fmap . fmap
-- @
fmapN :: forall (n :: Nat) a b s t. FmapN (ToPeano n) a b s t => (a -> b) -> s -> t
fmapN = fmapN' @(ToPeano n)

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Module: Gongju.Comonad
-- Description: Comonads, Distributive, and Representable Functors for Gongju
--
-- Plugs comonadic and distributive functor structures ('Comonad', 'Distributive',
-- 'Representable') into Gongju's open tape composition engine without modifying Core.
-- Allows non-Traversable comonads (such as Streams or Store) to commute with
-- Representable functors via distributive laws.
module Gongju.Comonad
  ( -- * Categorical Classes
    Comonad(..)
  , Distributive(..)
  , Representable(..)
    -- * Open Tags
  , PW
  , PWL
  , Dup
  , Ex
  , Dist
    -- * Ergonomic Aliases
  , W
  , WL
  , PullDist
  ) where

import Control.Comonad (Comonad (..))
import Data.Distributive (Distributive (..))
import Data.Functor.Rep (Representable (..))
import Gongju.Composition
  ( ApPath (..)
  , ApStep (..)
  , CommutePair (..)
  , F
  , InOrder
  , MapPath (..)
  , MapStep (..)
  , PullRet
  , StepPathMask (..)
  , StepRole (..)
  )
import Gongju.Peano (Append, Init)
import Gongju.Positional (ExpectArrow)

-- ---------------------------------------------------------------------------
-- 2. Open Mode & Layer Tags
-- ---------------------------------------------------------------------------

-- | Tag for lockstep Cokleisli argument consumption ('extend' / 'duplicate').
data PW

-- | Tag for layered Cokleisli argument consumption ('extend' adds an active layer).
data PWL

-- | Tag for Comonad context duplication ('duplicate').
data Dup

-- | Tag for Comonad focal value extraction ('extract').
data Ex

-- | Tag for Distributive and Representable functor layers.
data Dist

-- | In-order unindexed comonadic cokleisli alias.
type W = InOrder PW

-- | In-order unindexed layered comonadic cokleisli alias.
type WL = InOrder PWL

-- | Commute a 'Dist' layer outward past all active layers.
type PullDist = PullRet '[Dist]

-- ---------------------------------------------------------------------------
-- 3. Mapping, Zipping, and Commuting Instances
-- ---------------------------------------------------------------------------

instance (Distributive g, s ~ g s', t ~ g t', MapPath ls a b s' t')
  => MapStep Dist ls a b s t where
  mapStep f = fmap (mapPath @ls f)
  {-# INLINE mapStep #-}

instance (Representable g, fab ~ g fab', fa ~ g fa', fb ~ g fb', ApPath ls fab' fa' fb')
  => ApStep Dist ls fab fa fb where
  apStep fab fa = tabulate (\i -> apPath @ls (index fab i) (index fa i))
  {-# INLINE apStep #-}

-- | Right-driven Distributive law: commutes 'Dist' outside ANY 'Functor φ'.
instance (Functor φ, Distributive g, s ~ φ (g inner), t ~ g (φ inner))
  => CommutePair F Dist s t where
  commutePair = distribute
  {-# INLINE commutePair #-}

instance (Traversable g, Applicative φ, s ~ g (φ inner), t ~ φ (g inner))
  => CommutePair Dist F s t where
  commutePair = sequenceA
  {-# INLINE commutePair #-}

-- ---------------------------------------------------------------------------
-- 4. StepRole Instances (Comonad Transitions)
-- ---------------------------------------------------------------------------

instance (Comonad φ, ExpectArrow "StepRole PW" acc (φ a) rTail, wa ~ φ a, StepPathMask base '[ F ] ms m t3 (φ rTail) out')
  => StepRole PW base '[] ms m t3 acc (wa -> out') where
  stepRole f acc wa = stepPathMask @base @'[ F ] @ms f (extend acc wa)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out' φ a rTail wa.
  ( Comonad φ, wa ~ φ a
  , MapPath active (φ a -> rTail) (φ rTail) acc acc'
  , StepPathMask base (Append active '[ F ]) ms m t3 acc' out'
  ) => StepRole PWL base active ms m t3 acc (wa -> out') where
  stepRole f acc wa =
    stepPathMask @base @(Append active '[ F ]) @ms @m @t3 @acc' @out' f
      (mapPath @active @(φ a -> rTail) @(φ rTail) (`extend` wa) acc)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out φ inner.
  ( Comonad φ
  , MapPath (Init active) (φ inner) (φ (φ inner)) acc acc'
  , StepPathMask base (Append active '[ F ]) ms m t3 acc' out
  ) => StepRole Dup base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Append active '[ F ]) @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(φ inner) @(φ (φ inner)) duplicate acc)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out φ inner.
  ( Comonad φ
  , MapPath (Init active) (φ inner) inner acc acc'
  , StepPathMask base (Init active) ms m t3 acc' out
  ) => StepRole Ex base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Init active) @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(φ inner) @inner extract acc)
  {-# INLINE stepRole #-}

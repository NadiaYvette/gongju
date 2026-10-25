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

-- | Module: Gongju.Adjunction
-- Description: Adjunction transitions and dual-functor annihilation for Gongju
--
-- Plugs functor adjunctions ('Adjunction', @l ⊣ r@) from 'Data.Functor.Adjunction'
-- into Gongju's open tape composition engine without modifying Core.
--
-- Provides:
-- * Adjunction unit (@η : Id ⇒ R ∘ L@) and counit (@ε : L ∘ R ⇒ Id@) stack rewrites.
-- * Day-adjoint pairing ('zapLR', 'zapRL') that annihilates dual adjoint functor
--   contexts (1 + 1 → 0 active layers).
-- * Hom-set adjunct lifting ('leftAdjunct', 'rightAdjunct').
module Gongju.Adjunction
  ( -- * Re-exported Canonical Adjunction Class
    Adjunction(..)
  , zapWithAdjunction
  , indexAdjunction
  , tabulateAdjunction
    -- * Dual Annihilation Workers
  , zapLR
  , zapRL
    -- * Open Adjunction Tags
  , PAdjU
  , PAdjC
  , PZapLR
  , PZapRL
  , PAdjL
    -- * Ergonomic Aliases
  , AdjU
  , AdjC
  , ZapLR
  , ZapRL
  , AdjL
  ) where

import Data.Functor.Adjunction
  ( Adjunction (..)
  , indexAdjunction
  , tabulateAdjunction
  , zapWithAdjunction
  )
import Gongju.Composition
  ( F
  , InOrder
  , MapPath (..)
  , StepPathMask (..)
  , StepRole (..)
  )
import Gongju.Peano (Append, Init)

-- ---------------------------------------------------------------------------
-- 1. Dual Adjoint Pairing Workers
-- ---------------------------------------------------------------------------

-- | Annihilate left adjoint context @l (a -> b)@ and right adjoint context @r a@ into @b@.
zapLR :: Adjunction l r => l (a -> b) -> r a -> b
zapLR lab ra = counit (fmap (<$> ra) lab)
{-# INLINE zapLR #-}

-- | Dual annihilation: @r (a -> b)@ and @l a@ into @b@.
zapRL :: Adjunction l r => r (a -> b) -> l a -> b
zapRL rab la = counit (fmap (\a -> fmap ($ a) rab) la)
{-# INLINE zapRL #-}

-- ---------------------------------------------------------------------------
-- 2. Open Mode Tags & Aliases
-- ---------------------------------------------------------------------------

-- | Tag for inserting an adjunction unit: @a -> r (l a)@.
data PAdjU

-- | Tag for applying an adjunction counit: @l (r a) -> a@.
data PAdjC

-- | Tag for pairing active left-adjoint @l (a -> b)@ against caller @r a@ (annihilating both).
data PZapLR

-- | Tag for pairing active right-adjoint @r (a -> b)@ against caller @l a@ (annihilating both).
data PZapRL

-- | Tag for applying 'leftAdjunct': turns expectation of @l a@ into caller passing pure @a@.
data PAdjL

-- | In-order adjunction unit alias.
type AdjU = InOrder PAdjU

-- | In-order adjunction counit alias.
type AdjC = InOrder PAdjC

-- | In-order Day-adjoint pairing alias (left active, right caller).
type ZapLR = InOrder PZapLR

-- | In-order Day-adjoint pairing alias (right active, left caller).
type ZapRL = InOrder PZapRL

-- | In-order hom-set adjunct alias.
type AdjL = InOrder PAdjL

-- ---------------------------------------------------------------------------
-- 3. StepRole Instances (Adjunction Transitions)
-- ---------------------------------------------------------------------------

-- | Adjunction unit: expands inner tip to @r (l inner)@.
instance forall base active ms m t3 acc acc' out l r inner.
  ( Adjunction l r
  , MapPath (Init active) inner (r (l inner)) acc acc'
  , StepPathMask base (Append active '[ F, F ]) ms m t3 acc' out
  ) => StepRole PAdjU base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Append active '[ F, F ]) @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @inner @(r (l inner)) unit acc)
  {-# INLINE stepRole #-}

-- | Adjunction counit: collapses @l (r inner)@ at the tip down to @inner@.
instance forall base active ms m t3 acc acc' out l r inner.
  ( Adjunction l r
  , MapPath (Init (Init active)) (l (r inner)) inner acc acc'
  , StepPathMask base (Init (Init active)) ms m t3 acc' out
  ) => StepRole PAdjC base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Init (Init active)) @ms @m @t3 @acc' @out f
      (mapPath @(Init (Init active)) @(l (r inner)) @inner counit acc)
  {-# INLINE stepRole #-}

-- | ZapLR: Annihilates active left-adjoint layer with caller right-adjoint argument.
instance forall base active ms m t3 acc acc' out' l r a rem ra.
  ( Adjunction l r
  , ra ~ r a
  , MapPath (Init active) (l (a -> rem)) rem acc acc'
  , StepPathMask base (Init active) ms m t3 acc' out'
  ) => StepRole PZapLR base active ms m t3 acc (ra -> out') where
  stepRole f acc ra =
    stepPathMask @base @(Init active) @ms @m @t3 @acc' @out' f
      (mapPath @(Init active) @(l (a -> rem)) @rem (`zapLR` ra) acc)
  {-# INLINE stepRole #-}

-- | ZapRL: Annihilates active right-adjoint layer with caller left-adjoint argument.
instance forall base active ms m t3 acc acc' out' l r a rem la.
  ( Adjunction l r
  , la ~ l a
  , MapPath (Init active) (r (a -> rem)) rem acc acc'
  , StepPathMask base (Init active) ms m t3 acc' out'
  ) => StepRole PZapRL base active ms m t3 acc (la -> out') where
  stepRole f acc la =
    stepPathMask @base @(Init active) @ms @m @t3 @acc' @out' f
      (mapPath @(Init active) @(r (a -> rem)) @rem (`zapRL` la) acc)
  {-# INLINE stepRole #-}

-- | AdjL: Turns @l a -> rem@ in the accumulator into @a -> r rem@.
instance forall base active ms m t3 acc acc' out' l r a rem.
  ( Adjunction l r
  , MapPath active (l a -> rem) (r rem) acc acc'
  , StepPathMask base (Append active '[ F ]) ms m t3 acc' out'
  ) => StepRole PAdjL base active ms m t3 acc (a -> out') where
  stepRole f acc a =
    stepPathMask @base @(Append active '[ F ]) @ms @m @t3 @acc' @out' f
      (mapPath @active @(l a -> rem) @(r rem) (`leftAdjunct` a) acc)
  {-# INLINE stepRole #-}

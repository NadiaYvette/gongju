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

-- | Module: Gongju.Indexed
-- Description: Indexed Monads and Indexed Comonads for Gongju
--
-- Plugs indexed functorial structures ('IxFunctor', 'IxApplicative', 'IxMonad',
-- 'IxComonad') into Gongju's open tape composition engine without modifying Core.
module Gongju.Indexed
  ( -- * Re-exported Canonical Indexed Classes
    IxFunctor(..)
  , IxPointed(..)
  , IxCopointed(..)
  , IxApplicative(..)
  , ipure
  , iliftA2
  , IxMonad(..)
  , (>>>=)
  , (=<<<)
  , ijoin
  , IxComonad(..)
  , iduplicate
    -- * Open Indexed Tags
  , IxF
  , PIM
  , IJ
  , PIxW
  , IxDup
  , IxEx
    -- * Ergonomic Aliases
  , IxM
  , IxW
  ) where

import Control.Comonad.Indexed
  ( IxComonad (..)
  , iduplicate
  )
import Control.Monad.Indexed
  ( IxApplicative (..)
  , IxMonad (..)
  , ijoin
  , (=<<<)
  , (>>>=)
  )
import Data.Functor.Indexed
  ( IxCopointed (..)
  , IxFunctor (..)
  , IxPointed (..)
  )
import Data.Kind (Type)
import Gongju.Composition
  ( ApPath (..)
  , ApStep (..)
  , InOrder
  , MapPath (..)
  , MapStep (..)
  , StepPathMask (..)
  , StepRole (..)
  )
import Gongju.Peano (Append, Init)
import Gongju.Positional (ExpectArrow)

-- | Ergonomic alias for 'ireturn'.
ipure :: IxPointed m => a -> m i i a
ipure = ireturn
{-# INLINE ipure #-}

-- | Lift a binary function across two indexed applicatives.
iliftA2 :: IxApplicative m => (a -> b -> c) -> m i j a -> m j l b -> m i l c
iliftA2 f ma mb = iap (imap f ma) mb
{-# INLINE iliftA2 #-}

-- ---------------------------------------------------------------------------
-- 2. Open Indexed Tags
-- ---------------------------------------------------------------------------

-- | Tag for an indexed functor layer @m i j a@.
data IxF

-- | Tag for indexed monadic bind ('ibind').
data PIM

-- | Tag for indexed monadic join ('ijoin').
data IJ

-- | Tag for indexed comonadic extend ('iextend').
data PIxW

-- | Tag for indexed comonadic duplication ('iduplicate').
data IxDup

-- | Tag for indexed comonadic extraction ('iextract').
data IxEx

-- | In-order unindexed indexed monad bind alias.
type IxM = InOrder PIM

-- | In-order unindexed indexed comonad extend alias.
type IxW = InOrder PIxW

-- ---------------------------------------------------------------------------
-- 3. Mapping & Zipping Instances
-- ---------------------------------------------------------------------------

instance (IxFunctor m, s ~ m i j s', t ~ m i j t', MapPath ls a b s' t')
  => MapStep IxF ls a b s t where
  mapStep f = imap (mapPath @ls f)
  {-# INLINE mapStep #-}

instance (IxApplicative m, fab ~ m i j fab', fa ~ m j l fa', fb ~ m i l fb', ApPath ls fab' fa' fb')
  => ApStep IxF ls fab fa fb where
  apStep = iliftA2 (apPath @ls)
  {-# INLINE apStep #-}

-- ---------------------------------------------------------------------------
-- 4. StepRole Instances (IxMonad & IxComonad Transitions)
-- ---------------------------------------------------------------------------

instance (IxMonad φ, ExpectArrow "StepRole PIM" acc a rTail, fa ~ φ i j a, StepPathMask base '[ IxF ] ms m t3 (φ i j rTail) out')
  => StepRole PIM base '[] ms m t3 acc (fa -> out') where
  stepRole f acc fa = stepPathMask @base @'[ IxF ] @ms f (imap acc fa)
  {-# INLINE stepRole #-}

instance forall base l ls ms m t3 acc acc' out' idx (φ :: idx -> idx -> Type -> Type) i j rIdx a rTail fa.
  ( IxMonad φ, fa ~ φ j rIdx a
  , MapPath (Init (l ': ls)) (φ i j (a -> rTail)) (φ i rIdx rTail) acc acc'
  , StepPathMask base (l ': ls) ms m t3 acc' out'
  ) => StepRole PIM base (l ': ls) ms m t3 acc (fa -> out') where
  stepRole f acc fa =
    stepPathMask @base @(l ': ls) @ms @m @t3 @acc' @out' f
      (mapPath @(Init (l ': ls)) @(φ i j (a -> rTail)) @(φ i rIdx rTail)
        (\mf -> mf >>>= (`imap` fa)) acc)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out idx (φ :: idx -> idx -> Type -> Type) i j rIdx inner.
  ( IxMonad φ
  , MapPath (Init active) (φ i j (φ j rIdx inner)) (φ i rIdx inner) acc acc'
  , StepPathMask base active ms m t3 acc' out
  ) => StepRole IJ base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @active @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(φ i j (φ j rIdx inner)) @(φ i rIdx inner) ijoin acc)
  {-# INLINE stepRole #-}

instance ( IxComonad w
         , ExpectArrow "StepRole PIxW" acc (w j k a) rTail
         , wa ~ w i k a
         , StepPathMask base '[ IxF ] ms m t3 (w i j rTail) out'
         ) => StepRole PIxW base '[] ms m t3 acc (wa -> out') where
  stepRole f acc wa = stepPathMask @base @'[ IxF ] @ms f (iextend acc wa)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out' knd (w :: knd -> knd -> Type -> Type) i j k a rTail wa.
  ( IxComonad w
  , wa ~ w i k a
  , MapPath active (w j k a -> rTail) (w i j rTail) acc acc'
  , StepPathMask base (Append active '[ IxF ]) ms m t3 acc' out'
  ) => StepRole PIxW base active ms m t3 acc (wa -> out') where
  stepRole f acc wa =
    stepPathMask @base @(Append active '[ IxF ]) @ms @m @t3 @acc' @out' f
      (mapPath @active @(w j k a -> rTail) @(w i j rTail) (`iextend` wa) acc)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out knd (w :: knd -> knd -> Type -> Type) i j k inner.
  ( IxComonad w
  , MapPath (Init active) (w i k inner) (w i j (w j k inner)) acc acc'
  , StepPathMask base (Append active '[ IxF ]) ms m t3 acc' out
  ) => StepRole IxDup base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Append active '[ IxF ]) @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(w i k inner) @(w i j (w j k inner)) iduplicate acc)
  {-# INLINE stepRole #-}

instance forall base active ms m t3 acc acc' out knd (w :: knd -> knd -> Type -> Type) i inner.
  ( IxComonad w
  , MapPath (Init active) (w i i inner) inner acc acc'
  , StepPathMask base (Init active) ms m t3 acc' out
  ) => StepRole IxEx base active ms m t3 acc out where
  stepRole f acc =
    stepPathMask @base @(Init active) @ms @m @t3 @acc' @out f
      (mapPath @(Init active) @(w i i inner) @inner iextract acc)
  {-# INLINE stepRole #-}

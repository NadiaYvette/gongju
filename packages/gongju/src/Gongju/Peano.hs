{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Module: Gongju.Peano
-- Description: Bridge between GHC.TypeLits.Nat, inductive Peano data kinds, and type-level list utilities
--
-- Provides inductive Peano naturals for driving typeclass induction while exposing
-- ergonomic 'GHC.TypeLits.Nat' type application interfaces, as well as fundamental
-- inductive type-level list operations ('Append', 'Init', 'Replicate').
module Gongju.Peano
  ( Peano(..)
  , ToPeano
  , FromPeano
  , Append
  , Init
  , Replicate
  , Length
  ) where

import GHC.TypeLits (Nat, type (-), type (+))

{- Note [Peano TypeLits Bridge]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[tag:note-peano-typelits-bridge]
GHC's built-in 'GHC.TypeLits.Nat' represents numeric type literals (0, 1, 2, ...) as
known runtime symbols, which provides clean ergonomics for call sites (e.g. @compN @3@).
However, GHC's constraint solver cannot inductively pattern-match on '0' versus 'n + 1'
during standard typeclass instance resolution without generating overlapping or undecidable
instance loops.

Conversely, a custom inductive Peano data kind ('Z | 'S Peano) drives typeclass resolution
and bidirectional functional dependencies effortlessly by structurally peeling one successor
layer at a time.

By defining closed type families 'ToPeano' and 'FromPeano', Gongju bridges these two representations:
  - Callers use familiar numeric literals (@0, @1, @2, ...).
  - Typeclasses induct upon structural 'Peano' terms ('Z, 'S 'Z, 'S ('S 'Z), ...).
-}

-- | Inductive Peano natural numbers at the type level.
data Peano = Z | S Peano
  deriving (Eq, Show)

-- | Convert a 'GHC.TypeLits.Nat' into an inductive 'Peano' representation.
--
-- See Note [Peano TypeLits Bridge] [ref:note-peano-typelits-bridge].
type family ToPeano (n :: Nat) :: Peano where
  ToPeano 0 = 'Z
  ToPeano n = 'S (ToPeano (n - 1))

-- | Convert an inductive 'Peano' representation back to a 'GHC.TypeLits.Nat'.
type family FromPeano (p :: Peano) :: Nat where
  FromPeano 'Z     = 0
  FromPeano ('S p) = 1 + FromPeano p

-- | Concatenate two type-level lists.
type family Append (xs :: [k]) (ys :: [k]) :: [k] where
  Append '[]       ys = ys
  Append (x ': xs) ys = x ': Append xs ys

-- | Return all elements of a type-level list except the last element.
type family Init (xs :: [k]) :: [k] where
  Init '[]       = '[]
  Init '[_]      = '[]
  Init (x ': xs) = x ': Init xs

-- | Generate a type-level list containing @n@ copies of element @x@.
type family Replicate (n :: Nat) (x :: k) :: [k] where
  Replicate 0 _ = '[]
  Replicate n x = x ': Replicate (n - 1) x

-- | Compute the length of a type-level list as an inductive 'Peano' natural.
type family Length (xs :: [k]) :: Peano where
  Length '[]       = 'Z
  Length (_ ': xs) = 'S (Length xs)

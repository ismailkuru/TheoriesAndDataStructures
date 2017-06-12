module Structures.All where

-- Creates forgetful functors from single sorted algebras to |Set|
-- 
import Forget

-- Re-exports all equality-related concepts
--
import EqualityCombinators

-- Contains properties about sums and products not found in standard library
--
import DataProperties

-- Houses contents brought over from RATH-Agda library.
-- import RATH
-- ‼ This module is not being called from anywhere ‼  June 9, 2017.

import Structures.AbelianGroup

import Structures.Magma        

-- Considers |Set²|, pairs of sets.
--
import Structures.TwoSorted    

-- Considers pairs of sets along with a relation between them.
--
import Structures.Rel

import Structures.Semigroup    

-- A type along with a value of that type.
--
-- import Structures.Pointed
-- Currently has a hole

import Structures.UnaryAlgebra 

import Structures.Monoid       

-- import Structures.Dependent
-- unsolved metas

-- import Structures.DistinguishedSubset
-- constraint issues


import Structures.IndexedUnaryAlgebra

import Structures.InvolutiveAlgebra

-- import Structures.BagEquivalence

-- import Structures.CommMonoid

import SetoidEquiv
import SetoidOfIsos
import SetoidSetoid
import Structures.CommMonoidTerm

\section{Some}

%{{{ Imports
\begin{code}
module Some where

open import Level renaming (zero to lzero; suc to lsuc) hiding (lift)
open import Relation.Binary using (Setoid ; IsEquivalence ; Rel ;
  Reflexive ; Symmetric ; Transitive)

open import Function.Equality using (Π ; _⟶_ ; id ; _∘_ ; _⟨$⟩_ ; cong )
open import Function          using (_$_) renaming (id to id₀; _∘_ to _⊚_)
open import Function.Equivalence using (Equivalence)

open import Data.List     using (List; []; _++_; _∷_; map)
open import Data.Product  using (∃)
open import Data.Nat      using (ℕ; zero; suc)

open import EqualityCombinators
open import DataProperties
open import SetoidEquiv
open import ParComp

open import TypeEquiv using (swap₊)
open import SetoidSetoid
open import Relation.Binary.Sum

infix 4 inSetoidEquiv
inSetoidEquiv : {a ℓ : Level} → (S : Setoid a ℓ) → Setoid.Carrier S → Setoid.Carrier S → Set ℓ
inSetoidEquiv = Setoid._≈_

syntax inSetoidEquiv S x y = x ≈⌊ S ⌋ y
\end{code}
%}}}

The goal of this section is to capture a notion that we have a proof
of a property |P| of an element |x| belonging to a list |xs|.  But we don't
want just any proof, but we want to know \emph{which} |x ∈ xs| is the witness.
However, we are in the |Setoid| setting, and in a setting where multiplicity
matters (i.e. we may have |x| occuring twice in |xs|, yielding two different
proofs that |P| holds). And we do not care very much about the exact |x|,
any |y| such that |x ≈ y| will do, as long as it is in the ``right'' location.

And then we want to capture the idea of when two such are equivalent --
when is it that |Some P xs| is just as good as |Some P ys|?  In fact, we'll
generalize this some more to |Some Q ys|.

For the purposes of |CommMonoid| however, all we really need is some notion
of Bag Equivalence.  However, many of the properties we need to establish
are simpler if we generalize to the situation described above.
%{{{ \subsection{|Some₀|}
\subsection{|Some₀|}
|Setoid|-based variant of Any.

Quite a bit of this is directly inspired by |Data.List.Any| and |Data.List.Any.Properties|.

\edcomm{WK}{|A ⟶ SSetoid _ _| is a pretty strong assumption.
Logical equivalence does not ask for the two morphisms back and forth to be inverse.}
\edcomm{JC}{This is pretty much directly influenced by Nisse's paper: logical equivalence
only gives Set, not Multiset, at least if used for the equivalence of over List.  To
get Multiset, we need to preserve full equivalence, i.e. capture permutations.  My reason
to use |A ⟶ SSetoid _ _| is to mesh well with the rest.  It is not cast in stone and
can potentially be weakened.}

\edcomm{WK}{|S| would better be explicit.}
\begin{code}
module _ {a ℓa} {S : Setoid a ℓa} (P₀ : Setoid.Carrier S → Set ℓa) where
   open Setoid S renaming (Carrier to A)
   data Some₀  : List A → Set (a ⊔ ℓa) where
     here  : {x a : A} {xs : List A} (sm : a ≈ x) (px  : P₀ a    ) → Some₀ (x ∷ xs)
     there : {x   : A} {xs : List A}              (pxs : Some₀ xs) → Some₀ (x ∷ xs)
\end{code}

Inhabitants of |Some₀| really are just locations:
|Some₀ P xs  ≅ Σ i ∶ Fin (length xs) • P (x ‼ i)|.
Thus one possibility is to go with natural numbers directly,
but that seems awkward. Nevertheless, the 'location' function
is straightforward:
\begin{code}
   toℕ : {xs : List A} → Some₀ xs → ℕ
   toℕ (here _ _) = 0
   toℕ (there pf) = suc (toℕ pf)
\end{code}

\begin{code}
module _ {a ℓa} {S : Setoid a ℓa} {P₀ : Setoid.Carrier S → Set ℓa} where
   open Setoid S renaming (Carrier to A)
   infix 3 _≋_
   data _≋_ : {ys : List A} (pf pf' : Some₀ {S = S} P₀ ys) → Set (a ⊔ ℓa) where
     hereEq : {xs : List A} {x y z : A} (px : P₀ x) (qy : P₀ y)
            → (x≈z : x ≈ z) → (y≈z : y ≈ z)
            → _≋_ (here {x = z} {x} {xs} x≈z px) (here {x = z} {y} {xs} y≈z qy)
     thereEq : {xs : List A} {x : A} {pxs : Some₀ P₀ xs} {qxs : Some₀ P₀ xs}
             → _≋_ pxs qxs → _≋_ (there {x = x} pxs) (there {x = x} qxs)
\end{code}

Notice that these another from of ``natural numbers'' whose elements are of the form
|thereEqⁿ (hereEq Px Qx _ _)| for some |n : ℕ|.

It is on purpose that |_≋_| preserves positions.  Suppose that we take the setoid of
the Latin alphabet, with |_≈_| identifying upper and lower case. There should be
3 elements of |_≋_| for | a ∷ A ∷ a ∷ [] |, not 6.  When we get to defining |BagEq|,
there will be 6 different ways in which that list, as a Bag, is equivalent to itself.

\begin{code}
module _ {a ℓa} {S : Setoid a ℓa} {P₀ : Setoid.Carrier S → Set ℓa} where
   open Setoid S renaming (Carrier to A)
   ≋-refl : {xs : List A} {p : Some₀ {S = S} P₀ xs} → p ≋ p
   ≋-refl {p = here a≈x px} = hereEq px px a≈x a≈x
   ≋-refl {p = there p} = thereEq ≋-refl

   ≋-sym : {xs : List A} {p : Some₀ {S = S} P₀ xs} {q : Some₀ P₀ xs} → p ≋ q → q ≋ p
   ≋-sym (hereEq a≈x b≈x px py) = hereEq b≈x a≈x py px
   ≋-sym (thereEq eq) = thereEq (≋-sym eq)

   ≋-trans : {xs : List A} {p q r : Some₀ {S = S} P₀ xs}
           → p ≋ q → q ≋ r → p ≋ r
   ≋-trans (hereEq pa qb a≈x b≈x) (hereEq pc qd c≈y d≈y) = hereEq pa qd _ _
   ≋-trans (thereEq e) (thereEq f) = thereEq (≋-trans e f)

   ≡→≋ : {xs : List A} {p q : Some₀ {S = S} P₀ xs} → p ≡ q → p ≋ q
   ≡→≋ ≡.refl = ≋-refl

module _ {a ℓa} {A : Setoid a ℓa} (P : A ⟶ SSetoid ℓa ℓa) where
   open Setoid A
   private P₀ = λ e → Setoid.Carrier (Π._⟨$⟩_ P e)

   Some : List Carrier → Setoid (ℓa ⊔ a) (ℓa ⊔ a)
   Some xs = record
     { Carrier         =   Some₀ {S = A} P₀ xs
     ; _≈_             =   _≋_
     ; isEquivalence   = record { refl = ≋-refl ; sym = ≋-sym ; trans = ≋-trans }
     }

≡→Some : {a ℓa : Level} {A : Setoid a ℓa} {P : A ⟶ SSetoid ℓa ℓa}
         {xs ys : List (Setoid.Carrier A)} → xs ≡ ys → Some P xs ≅ Some P ys
≡→Some {A = A} ≡.refl = ≅-refl
\end{code}
%}}}

%{{{ \subsection{Membership module}: setoid≈ ; _∈_ ; _∈₀_
\subsection{Membership module}

\edcomm{WK}{Please don't waste valuable variable names on levels.}
\edcomm{JC}{Good point.}
\savecolumns
\begin{code}
module Membership {ℓS ℓs : Level} (S : Setoid ℓS ℓs) where

  open Setoid S renaming (trans to _⟨≈≈⟩_)

  infix 4 _∈₀_ _∈_
\end{code}

|setoid≈ x| is actually a mapping from |S| to |SSetoid _ _|; it maps
elements |y| of |Carrier S| to the setoid of "|x ≈ₛ y|".

\restorecolumns
\begin{code}
  setoid≈ : Carrier → S ⟶ SSetoid ℓs ℓs
  setoid≈ x = record
    { _⟨$⟩_ = λ (y : Carrier) → _≈S_ {A = S} x y
    ; cong = λ i≈j → record
      { to = record { _⟨$⟩_ = λ x≈i → x≈i ⟨≈≈⟩ i≈j ; cong = λ _ → tt }
      ; from = record { _⟨$⟩_ = λ x≈j → x≈j ⟨≈≈⟩ sym i≈j ; cong = λ _ → tt }
      }
    }

  _∈_ : Carrier → List Carrier → Setoid (ℓS ⊔ ℓs) (ℓS ⊔ ℓs)
  x ∈ xs = Some (setoid≈ x) xs

  _∈₀_ : Carrier → List Carrier → Set (ℓS ⊔ ℓs)
  x ∈₀ xs = Setoid.Carrier (x ∈ xs)

  ∈₀-subst₁ : {x y : Carrier} {xs : List Carrier} → x ≈ y → x ∈₀ xs → y ∈₀ xs
  ∈₀-subst₁ {x} {y} {.(_ ∷ _)} x≈y (here a≈x px) = here a≈x (sym x≈y ⟨≈≈⟩ px)
  ∈₀-subst₁ {x} {y} {.(_ ∷ _)} x≈y (there x∈xs) = there (∈₀-subst₁ x≈y x∈xs)

  ∈₀-subst₁-equiv  : {x y : Carrier} {xs : List Carrier} → x ≈ y → (x ∈ xs) ≅ (y ∈ xs)
  ∈₀-subst₁-equiv {x} {y} {xs} x≈y = record
    { to = record { _⟨$⟩_ = ∈₀-subst₁ x≈y ; cong = ∈₀-subst₁-cong }
    ; from = record { _⟨$⟩_ = ∈₀-subst₁ (sym x≈y) ; cong = ∈₀-subst₁-cong′ }
    ; inverse-of = record { left-inverse-of = left-inv ; right-inverse-of = right-inv } }
    where
      ∈₀-subst₁-cong : ∀ {ys} {i j : x ∈₀ ys} → i ≋ j → ∈₀-subst₁ x≈y i ≋ ∈₀-subst₁ x≈y j
      ∈₀-subst₁-cong (hereEq px qy x≈z y≈z) = hereEq (sym x≈y ⟨≈≈⟩ px ) (sym x≈y ⟨≈≈⟩ qy) x≈z y≈z
      ∈₀-subst₁-cong (thereEq i≋j) = thereEq (∈₀-subst₁-cong i≋j)

      ∈₀-subst₁-cong′ : ∀ {ys} {i j : y ∈₀ ys} → i ≋ j → ∈₀-subst₁ (sym x≈y) i ≋ ∈₀-subst₁ (sym x≈y) j
      ∈₀-subst₁-cong′ (hereEq px qy x≈z y≈z) = hereEq (sym (sym x≈y) ⟨≈≈⟩ px) (sym (sym x≈y) ⟨≈≈⟩ qy) x≈z y≈z
      ∈₀-subst₁-cong′ (thereEq i≋j) = thereEq (∈₀-subst₁-cong′ i≋j)

      left-inv : ∀ {ys} (x∈ys : x ∈₀ ys) → ∈₀-subst₁ (sym x≈y) (∈₀-subst₁ x≈y x∈ys) ≋ x∈ys
      left-inv (here sm px) = hereEq (sym (sym x≈y) ⟨≈≈⟩ (sym x≈y ⟨≈≈⟩ px)) px sm sm
      left-inv (there x∈ys) = thereEq (left-inv x∈ys)

      right-inv : ∀ {ys} (y∈ys : y ∈₀ ys) → ∈₀-subst₁ x≈y (∈₀-subst₁ (sym x≈y) y∈ys) ≋ y∈ys
      right-inv (here sm px) = hereEq (sym x≈y ⟨≈≈⟩ (sym (sym x≈y) ⟨≈≈⟩ px)) px sm sm
      right-inv (there y∈ys) = thereEq (right-inv y∈ys)

  BagEq : (xs ys : List Carrier) → Set (ℓS ⊔ ℓs)
  BagEq xs ys = {x : Carrier} → (x ∈ xs) ≅ (x ∈ ys)

  ∈₀-Subst₂ : {x : Carrier} {xs ys : List Carrier} → BagEq xs ys → x ∈ xs ⟶ x ∈ ys
  ∈₀-Subst₂ {x} {xs} {ys} xs≅ys = _≅_.to (xs≅ys {x})

  ∈₀-subst₂ : {x : Carrier} {xs ys : List Carrier} → BagEq xs ys → x ∈₀ xs → x ∈₀ ys
  ∈₀-subst₂ xs≅ys x∈xs = ∈₀-Subst₂ xs≅ys ⟨$⟩ x∈xs

  ∈₀-subst₂-cong  : {x : Carrier} {xs ys : List Carrier} (xs≅ys : BagEq xs ys)
                  → {p q : x ∈₀ xs}
                  → p ≈⌊ x ∈ xs ⌋ q
                  → ∈₀-subst₂ xs≅ys p ≈⌊ x ∈ ys ⌋ ∈₀-subst₂ xs≅ys q
  ∈₀-subst₂-cong xs≅ys = cong (∈₀-Subst₂ xs≅ys)

  transport : (Q : S ⟶ SSetoid ℓs ℓs) →
    let Q₀ = λ e → Setoid.Carrier (Q ⟨$⟩ e) in
    {a x : Carrier} (p : Q₀ a) (a≈x : a ≈ x) → Q₀ x
  transport Q p a≈x = Equivalence.to (Π.cong Q a≈x) ⟨$⟩ p

  ∈₀-subst₁-elim : {x : Carrier} {xs : List Carrier} (x∈xs : x ∈₀ xs) →
    ∈₀-subst₁ refl x∈xs ≋ x∈xs
  ∈₀-subst₁-elim (here sm px) = hereEq (sym refl ⟨≈≈⟩ px) px sm sm
  ∈₀-subst₁-elim (there x∈xs) = thereEq (∈₀-subst₁-elim x∈xs)

  -- note how the back-and-forth is clearly apparent below
  ∈₀-subst₁-sym : {a b : Carrier} {xs : List Carrier} {a≈b : a ≈ b}
    {a∈xs : a ∈₀ xs} {b∈xs : b ∈₀ xs} → ∈₀-subst₁ a≈b a∈xs ≋ b∈xs →
    ∈₀-subst₁ (sym a≈b) b∈xs ≋ a∈xs
  ∈₀-subst₁-sym {a≈b = a≈b} {here sm px} {here sm₁ px₁} (hereEq _ .px₁ .sm .sm₁) = hereEq (sym (sym a≈b) ⟨≈≈⟩ px₁) px sm₁ sm
  ∈₀-subst₁-sym {a∈xs = there a∈xs} {here sm px} ()
  ∈₀-subst₁-sym {a∈xs = here sm px} {there b∈xs} ()
  ∈₀-subst₁-sym {a∈xs = there a∈xs} {there b∈xs} (thereEq pf) = thereEq (∈₀-subst₁-sym pf)

  ∈₀-subst₁-trans : {a b c : Carrier} {xs : List Carrier} {a≈b : a ≈ b}
    {b≈c : b ≈ c} {a∈xs : a ∈₀ xs} {b∈xs : b ∈₀ xs} {c∈xs : c ∈₀ xs} →
    ∈₀-subst₁ a≈b a∈xs ≋ b∈xs → ∈₀-subst₁ b≈c b∈xs ≋ c∈xs →
    ∈₀-subst₁ (a≈b ⟨≈≈⟩ b≈c) a∈xs ≋ c∈xs
  ∈₀-subst₁-trans {a≈b = a≈b} {b≈c} {here sm px} {.(here y≈z qy)} {.(here z≈w qz)} (hereEq ._ qy .sm y≈z) (hereEq ._ qz foo z≈w) = hereEq (sym (a≈b ⟨≈≈⟩ b≈c) ⟨≈≈⟩ px) qz sm z≈w
  ∈₀-subst₁-trans {a≈b = a≈b} {b≈c} {there a∈xs} {there b∈xs} {.(there _)} (thereEq pp) (thereEq qq) = thereEq (∈₀-subst₁-trans pp qq)
\end{code}

\edcomm{WK}{Trying --- but |BagEq| still does not preserve positions!
\edcomm{JC}{And it is not supposed to preserve them.  |BagEq| is a permutation.}
Commented out:
\begin{code}
  infix  3 _□
  infixr 2 _≋⟨_⟩_

  _≋⟨_⟩_ : {P₀ : Carrier → Set ℓs} {xs : List Carrier} (X : Some₀ {S = S} P₀ xs) {Y Z : Some₀ P₀ xs}
        →  X ≋ Y → Y ≋ Z → X ≋ Z
  X ≋⟨ X≋Y ⟩ Y≋Z = ≋-trans X≋Y Y≋Z

  _□ : {P₀ : Carrier → Set ℓs} {xs : List Carrier} (X : Some₀ {S = S} P₀ xs) → X ≋ X
  X □ = ≋-refl

  here≋there : {P₀ : Carrier → Set ℓs} {xs : List Carrier} {a x : Carrier} {a≈x : a ≈ x}
    {Pa : P₀ a} {pf : Some₀ {S = S} P₀ xs } →
    here {x = x} {a} {xs} a≈x Pa ≋ there pf → ⊥ {ℓS}
  here≋there ()

  private
    Some[]→⊥ : {P₀ : Carrier → Set ℓs} → Some₀ {ℓS} {ℓs} {S} P₀ [] → ⊥ {ℓs}
    Some[]→⊥ ()

{-
  ∈₀-subst₁-to : {a b : Carrier} {zs ws : List Carrier} {a≈b : a ≈ b}
      → (zs≅ws : BagEq zs ws) (a∈zs : a ∈₀ zs)
      → ∈₀-subst₂ zs≅ws a∈zs ≋ ∈₀-subst₂ (≋-trans (∈₀-subst₁-equiv a≈b) zs≅ws) ?
  ∈₀-subst₁-to {a} {b} {zs} {ws} {a≈b} zs≅ws a∈zs = {!!}
-}
\end{code}
}%edcomm

\begin{code}
  postulate
    ∈₀-subst₁-to′ : {a b : Carrier} {zs ws : List Carrier} {a≈b : a ≈ b} (eq : BagEq zs ws)
      (a∈zs : a ∈₀ zs) → ∈₀-subst₁ a≈b (∈₀-subst₂ eq a∈zs) ≋ ∈₀-subst₂ eq (∈₀-subst₁ a≈b a∈zs)
\end{code}
%}}}

%{{{ -- module NICE
\edcomm{WK}{A |BagEq| that is easily recognised as not just a permutation on indices.

Commented out since there are still holes.

\begin{spec}
module NICE where
  open import Data.Bool
  data Nice {ℓA : Level} {A : Set ℓA} (x : A) : A → Set where
    nice : Bool → Nice x x

  NiceSetoid : {ℓA : Level} → Set ℓA → Setoid ℓA lzero
  NiceSetoid A = record
    { Carrier = A
    ; _≈_ = Nice
    ; isEquivalence = record
      { refl = nice true
      ; sym = λ { (nice b) → nice (not b) }
      ; trans = λ { (nice b₁) (nice b₂) → nice (b₁ xor b₂) }
      }
    }

  data E : Set where
    E₁ E₂ : E

  xs ys : List E
  xs = E₁ ∷ E₂ ∷ E₂ ∷ []
  ys = E₂ ∷ E₁ ∷ E₂ ∷ []

  open Membership (NiceSetoid E)

  xs⇒ys : (e : E)  → Some₀ {S = NiceSetoid E} (Nice e) xs
                   → Some₀ {S = NiceSetoid E} (Nice e) ys
  xs⇒ys E₁ (here (nice false) (nice false)) = there (here (nice false) (nice true))
  xs⇒ys E₁ (here (nice false) (nice true)) = there (here (nice true) (nice true))
  xs⇒ys E₁ (here (nice true) (nice false)) = there (here (nice false) (nice false))
  xs⇒ys E₁ (here (nice true) (nice true)) = there (here (nice true) (nice false))
  xs⇒ys E₁ (there (here (nice x) ()))
  xs⇒ys E₁ (there (there (here (nice x) ())))
  xs⇒ys E₁ (there (there (there ())))
  xs⇒ys E₂ (here (nice x) ())
  xs⇒ys E₂ (there (here (nice false) (nice false))) = here (nice true) (nice true)
  xs⇒ys E₂ (there (here (nice false) (nice true))) = there (there (here (nice true) (nice true)))
  xs⇒ys E₂ (there (here (nice true) (nice false))) = here (nice true) (nice false)
  xs⇒ys E₂ (there (here (nice true) (nice true))) = there (there (here (nice false) (nice true)))
  xs⇒ys E₂ (there (there (here (nice false) (nice false)))) = here (nice false) (nice false)
  xs⇒ys E₂ (there (there (here (nice false) (nice true)))) = there (there (here (nice true) (nice false)))
  xs⇒ys E₂ (there (there (here (nice true) (nice false)))) = there (there (here (nice false) (nice false)))
  xs⇒ys E₂ (there (there (here (nice true) (nice true)))) = here (nice false) (nice true)
  xs⇒ys E₂ (there (there (there ())))

  xs⇒ys-cong : (e : E) {i j : Some₀ (Nice e) xs} → i ≋ j → xs⇒ys e i ≋ xs⇒ys e j
  xs⇒ys-cong E₁ {.(here (nice false) (nice false))} {.(here (nice false) (nice false))} (hereEq (nice false) (nice false) (nice false) (nice false)) = thereEq (hereEq (nice true) (nice true) (nice false) (nice false))
  xs⇒ys-cong E₁ {.(here (nice false) (nice false))} {.(here (nice true) (nice false))} (hereEq (nice false) (nice false) (nice false) (nice true)) = thereEq (hereEq (nice true) (nice false) (nice false) (nice false))
  xs⇒ys-cong E₁ {.(here (nice true) (nice false))} {.(here (nice false) (nice false))} (hereEq (nice false) (nice false) (nice true) (nice false)) = thereEq (hereEq (nice false) (nice true) (nice false) (nice false))
  xs⇒ys-cong E₁ {.(here (nice true) (nice false))} {.(here (nice true) (nice false))} (hereEq (nice false) (nice false) (nice true) (nice true)) = thereEq
                                                                                                                                                     (hereEq (nice false) (nice false) (nice false) (nice false))
  xs⇒ys-cong E₁ {.(here (nice false) (nice false))} {.(here (nice false) (nice true))} (hereEq (nice false) (nice true) (nice false) (nice false)) = thereEq (hereEq (nice true) (nice true) (nice false) (nice true))
  xs⇒ys-cong E₁ {.(here (nice false) (nice false))} {.(here (nice true) (nice true))} (hereEq (nice false) (nice true) (nice false) (nice true)) = thereEq (hereEq (nice true) (nice false) (nice false) (nice true))
  xs⇒ys-cong E₁ {.(here (nice true) (nice false))} {.(here (nice false) (nice true))} (hereEq (nice false) (nice true) (nice true) (nice false)) = thereEq (hereEq (nice false) (nice true) (nice false) (nice true))
  xs⇒ys-cong E₁ {.(here (nice true) (nice false))} {.(here (nice true) (nice true))} (hereEq (nice false) (nice true) (nice true) (nice true)) = thereEq (hereEq (nice false) (nice false) (nice false) (nice true))
  xs⇒ys-cong E₁ {.(here (nice false) (nice true))} {.(here (nice false) (nice false))} (hereEq (nice true) (nice false) (nice false) (nice false)) = thereEq (hereEq (nice true) (nice true) (nice true) (nice false))
  xs⇒ys-cong E₁ {.(here (nice false) (nice true))} {.(here (nice true) (nice false))} (hereEq (nice true) (nice false) (nice false) (nice true)) = thereEq (hereEq (nice true) (nice false) (nice true) (nice false))
  xs⇒ys-cong E₁ {.(here (nice true) (nice true))} {.(here (nice false) (nice false))} (hereEq (nice true) (nice false) (nice true) (nice false)) = thereEq (hereEq (nice false) (nice true) (nice true) (nice false))
  xs⇒ys-cong E₁ {.(here (nice true) (nice true))} {.(here (nice true) (nice false))} (hereEq (nice true) (nice false) (nice true) (nice true)) = thereEq (hereEq (nice false) (nice false) (nice true) (nice false))
  xs⇒ys-cong E₁ {.(here (nice false) (nice true))} {.(here (nice false) (nice true))} (hereEq (nice true) (nice true) (nice false) (nice false)) = thereEq (hereEq (nice true) (nice true) (nice true) (nice true))
  xs⇒ys-cong E₁ {.(here (nice false) (nice true))} {.(here (nice true) (nice true))} (hereEq (nice true) (nice true) (nice false) (nice true)) = thereEq (hereEq (nice true) (nice false) (nice true) (nice true))
  xs⇒ys-cong E₁ {.(here (nice true) (nice true))} {.(here (nice false) (nice true))} (hereEq (nice true) (nice true) (nice true) (nice false)) = thereEq (hereEq (nice false) (nice true) (nice true) (nice true))
  xs⇒ys-cong E₁ {.(here (nice true) (nice true))} {.(here (nice true) (nice true))} (hereEq (nice true) (nice true) (nice true) (nice true)) = thereEq (hereEq (nice false) (nice false) (nice true) (nice true))
  xs⇒ys-cong E₁ {.(there (here _ (nice x)))} {.(there (here y≈z (nice x₁)))} (thereEq (hereEq (nice x) (nice x₁) () y≈z))
  xs⇒ys-cong E₁ {.(there (there (here _ (nice x))))} {.(there (there (here y≈z (nice x₁))))} (thereEq (thereEq (hereEq (nice x) (nice x₁) () y≈z)))
  xs⇒ys-cong E₁ {.(there (there (there _)))} {.(there (there (there _)))} (thereEq (thereEq (thereEq ())))
  xs⇒ys-cong E₂ {.(here x≈z px)} {.(here y≈z qy)} (hereEq px qy x≈z y≈z) = {!!}
  xs⇒ys-cong E₂ {.(there _)} {.(there _)} (thereEq i≋j) = {!!}

  ys⇒xs : (e : E)  → Some₀ {S = NiceSetoid E} (Nice e) ys
                   → Some₀ {S = NiceSetoid E} (Nice e) xs
  ys⇒xs e p = {!!}


  xs≊ys : BagEq xs ys
  xs≊ys {e} = record
    { to = record { _⟨$⟩_ = xs⇒ys e ; cong = xs⇒ys-cong e }
    ; from = record { _⟨$⟩_ = ys⇒xs e ; cong = {!!} }
    ; inverse-of = {!!}
    }
\end{spec}
}%edcomm
%}}}

%{{{ \subsection{|++≅ : ⋯ → (Some P xs ⊎⊎ Some P ys) ≅ Some P (xs ++ ys)|}
\subsection{|++≅ : ⋯ → (Some P xs ⊎⊎ Some P ys) ≅ Some P (xs ++ ys)|}
\begin{code}
module _ {a ℓa : Level} {A : Setoid a ℓa} {P : A ⟶ SSetoid ℓa ℓa} where
  ++≅ : {xs ys : List (Setoid.Carrier A) } → (Some P xs ⊎⊎ Some P ys) ≅ Some P (xs ++ ys)
  ++≅ {xs} {ys} = record
    { to = record { _⟨$⟩_ = ⊎→++ ; cong =  ⊎→++-cong  }
    ; from = record { _⟨$⟩_ = ++→⊎ xs ; cong = new-cong xs }
    ; inverse-of = record
      { left-inverse-of = lefty xs
      ; right-inverse-of = righty xs
      }
    }
    where
      open Setoid A
      private P₀ = λ e → Setoid.Carrier (P ⟨$⟩ e)
      _∽_ = _≋_ ; ∽-refl = ≋-refl {S = A} {P₀}

      -- ``ealier''
      ⊎→ˡ : ∀ {ws zs} → Some₀ {S = A} P₀ ws → Some₀ {S = A} P₀ (ws ++ zs)
      ⊎→ˡ (here p a≈x) = here p a≈x
      ⊎→ˡ (there p) = there (⊎→ˡ p)

      yo : {xs : List Carrier} {x y : Some₀ P₀ xs} → x ∽ y   →   ⊎→ˡ x  ∽  ⊎→ˡ y
      yo (hereEq px py _ _) = hereEq px py _ _
      yo (thereEq pf) = thereEq (yo pf)

      -- ``later''
      ⊎→ʳ : ∀ xs {ys} → Some₀ {S = A} P₀ ys → Some₀ P₀ (xs ++ ys)
      ⊎→ʳ []       p = p
      ⊎→ʳ (x ∷ xs) p = there (⊎→ʳ xs p)

      oy : (xs : List Carrier) {x y : Some₀ P₀ ys} → x ∽ y   →   ⊎→ʳ xs x  ∽  ⊎→ʳ xs y
      oy [] pf = pf
      oy (x ∷ xs) pf = thereEq (oy xs pf)

      -- |Some₀| is |++→⊎|-homomorphic, in the second argument.

      ⊎→++ : ∀ {zs ws} → (Some₀ P₀ zs ⊎ Some₀ P₀ ws) → Some₀ P₀ (zs ++ ws)
      ⊎→++      (inj₁ x) = ⊎→ˡ x
      ⊎→++ {zs} (inj₂ y) = ⊎→ʳ zs y

      ++→⊎ : ∀ xs {ys} → Some₀ P₀ (xs ++ ys) → Some₀ P₀ xs ⊎ Some₀ P₀ ys
      ++→⊎ []             p    = inj₂ p
      ++→⊎ (x ∷ l) (here  p _) = inj₁ (here p _)
      ++→⊎ (x ∷ l) (there p)   = (there ⊎₁ id₀) (++→⊎ l p)

      -- all of the following may need to change

      ⊎→++-cong : {a b : Some₀ P₀ xs ⊎ Some₀ P₀ ys} → (_∽_ ∥ _∽_) a b → ⊎→++ a ∽ ⊎→++ b
      ⊎→++-cong (left  x₁∼x₂)  =  yo x₁∼x₂
      ⊎→++-cong (right y₁∼y₂)  =  oy xs y₁∼y₂

      ∽∥∽-cong   :  {xs ys us vs : List Carrier}
                    (F : Some₀ {S = A} P₀ xs → Some₀ {S = A} P₀ us)
                    (F-cong : {p q : Some₀ P₀ xs} → p ∽ q → F p ∽ F q)
                    (G : Some₀ {S = A} P₀ ys → Some₀ {S = A} P₀ vs)
                    (G-cong : {p q : Some₀ P₀ ys} → p ∽ q → G p ∽ G q)
                    → {pf pf' : Some₀ P₀ xs ⊎ Some₀ P₀ ys}
                    → (_∽_ ∥ _∽_) pf pf' → (_∽_ ∥ _∽_) ( (F ⊎₁ G) pf) ((F ⊎₁ G) pf')
      ∽∥∽-cong F F-cong G G-cong (left x~₁y) = left (F-cong x~₁y)
      ∽∥∽-cong F F-cong G G-cong (right x~₂y) = right (G-cong x~₂y)

      new-cong : (xs : List Carrier) {i j : Some₀ P₀ (xs ++ ys)} → i ∽ j → (_∽_ ∥ _∽_) (++→⊎ xs i) (++→⊎ xs j)
      new-cong [] pf = right pf
      new-cong (x ∷ xs) (hereEq px py _ _) = left (hereEq px py _ _)
      new-cong (x ∷ xs) (thereEq pf) = ∽∥∽-cong there thereEq id₀ id₀ (new-cong xs pf)

      lefty : (xs {ys} : List Carrier) (p : Some₀ P₀ xs ⊎ Some₀ P₀ ys) → (_∽_ ∥ _∽_) (++→⊎ xs (⊎→++ p)) p
      lefty [] (inj₁ ())
      lefty [] (inj₂ p) = right ≋-refl
      lefty (x ∷ xs) (inj₁ (here px _)) = left ∽-refl
      lefty (x ∷ xs) {ys} (inj₁ (there p)) with ++→⊎ xs {ys} (⊎→++ (inj₁ p)) | lefty xs {ys} (inj₁ p)
      ... | inj₁ _ | (left x~₁y) = left (thereEq x~₁y)
      ... | inj₂ _ | ()
      lefty (z ∷ zs) {ws} (inj₂ p) with ++→⊎ zs {ws} (⊎→++ {zs} (inj₂ p)) | lefty zs (inj₂ p)
      ... | inj₁ x | ()
      ... | inj₂ y | (right x~₂y) = right x~₂y

      righty : (zs {ws} : List Carrier) (p : Some₀ P₀ (zs ++ ws)) → (⊎→++ (++→⊎ zs p)) ∽ p
      righty [] {ws} p = ∽-refl
      righty (x ∷ zs) {ws} (here px _) = ∽-refl
      righty (x ∷ zs) {ws} (there p) with ++→⊎ zs p | righty zs p
      ... | inj₁ _  | res = thereEq res
      ... | inj₂ _  | res = thereEq res
\end{code}
%}}}

%{{{ \subsection{Bottom as a setoid} ⊥⊥ ; ⊥≅Some[] : ⊥⊥ ≅ Some P []
\subsection{Bottom as a setoid}
\begin{code}
⊥⊥ : ∀ {a ℓa} → Setoid a ℓa
⊥⊥ {a} {ℓa} = record
  { Carrier = ⊥
  ; _≈_ = λ _ _ → ⊤
  ; isEquivalence = record { refl = tt ; sym = λ _ → tt ; trans = λ _ _ → tt }
  }
\end{code}

\begin{code}
module _ {a ℓa : Level} {A : Setoid a ℓa} {P : A ⟶ SSetoid ℓa ℓa} where

  ⊥≅Some[] : ⊥⊥ {a ⊔ ℓa} {a ⊔ ℓa} ≅ Some P []
  ⊥≅Some[] = record
    { to          =   record { _⟨$⟩_ = λ {()} ; cong = λ { {()} } }
    ; from        =   record { _⟨$⟩_ = λ {()} ; cong = λ { {()} } }
    ; inverse-of  =   record { left-inverse-of = λ _ → tt ; right-inverse-of = λ {()} }
    }
\end{code}
%}}}

%{{{ \subsection{|map≅ : ⋯→ Some (P ∘ f) xs ≅ Some P (map (_⟨$⟩_ f) xs)|}
\subsection{|map≅ : ⋯→ Some (P ∘ f) xs ≅ Some P (map (_⟨$⟩_ f) xs)|}
\begin{code}
map≅ : ∀ {a ℓa} {A B : Setoid a ℓa} {P : B ⟶ SSetoid ℓa ℓa} {f : A ⟶ B} {xs : List (Setoid.Carrier A)} →
       Some (P ∘ f) xs ≅ Some P (map (_⟨$⟩_ f) xs)
map≅ {a} {ℓa} {A} {B} {P} {f} = record
  { to = record { _⟨$⟩_ = map⁺ ; cong = map⁺-cong }
  ; from = record { _⟨$⟩_ = map⁻ ; cong = map⁻-cong }
  ; inverse-of = record { left-inverse-of = map⁻∘map⁺ ; right-inverse-of = map⁺∘map⁻ }
  }
  where
  open Setoid
  open Membership using (transport)
  A₀ = Carrier A
  P₀ = λ e → Setoid.Carrier (P ⟨$⟩ e)
  _∼_ = _≋_ {S = B} {P₀ = P₀}

  map⁺ : {xs : List A₀} → Some₀ {S = A} (P₀ ⊚ _⟨$⟩_ f) xs → Some₀ {S = B} P₀ (map (_⟨$⟩_ f) xs)
  map⁺ (here a≈x p)  = here (Π.cong f a≈x) p
  map⁺ (there p) = there $ map⁺ p

  map⁻ : {xs : List A₀} → Some₀ {S = B} P₀ (map (_⟨$⟩_ f) xs) → Some₀ {S = A} (P₀ ⊚ (_⟨$⟩_ f)) xs
  map⁻ {[]} ()
  map⁻ {x ∷ xs} (here {b} b≈x p) = here (refl A) (Equivalence.to (Π.cong P b≈x) ⟨$⟩ p)
  map⁻ {x ∷ xs} (there p) = there (map⁻ {xs = xs} p)

  map⁺∘map⁻ : {xs : List A₀ } → (p : Some₀ P₀ (map (_⟨$⟩_ f) xs)) → map⁺ (map⁻ p) ∼ p
  map⁺∘map⁻ {[]} ()
  map⁺∘map⁻ {x ∷ xs} (here b≈x p) = hereEq (transport B P p b≈x) p (Π.cong f (refl A)) b≈x
  map⁺∘map⁻ {x ∷ xs} (there p) = thereEq (map⁺∘map⁻ p)

  map⁻∘map⁺ : {xs : List A₀} → (p : Some₀ (P₀ ⊚ (_⟨$⟩_ f)) xs)
            → let _∼₂_ = _≋_ {P₀ = P₀ ⊚ (_⟨$⟩_ f)} in map⁻ (map⁺ p) ∼₂ p
  map⁻∘map⁺ {[]} ()
  map⁻∘map⁺ {x ∷ xs} (here a≈x p) = hereEq (transport A (P ∘ f) p a≈x) p (refl A) a≈x
  map⁻∘map⁺ {x ∷ xs} (there p) = thereEq (map⁻∘map⁺ p)

  map⁺-cong : {ys : List A₀} {i j : Some₀ (P₀ ⊚ _⟨$⟩_ f) ys} →  _≋_ {P₀ = P₀ ⊚ _⟨$⟩_ f} i j → map⁺ i ∼ map⁺ j
  map⁺-cong (hereEq px py x≈z y≈z) = hereEq px py (Π.cong f x≈z) (Π.cong f y≈z)
  map⁺-cong (thereEq i∼j) = thereEq (map⁺-cong i∼j)

  map⁻-cong : {ys : List A₀} {i j : Some₀ P₀ (map (_⟨$⟩_ f) ys)} → i ∼ j → _≋_ {P₀ = P₀ ⊚ _⟨$⟩_ f} (map⁻ i) (map⁻ j)
  map⁻-cong {[]} ()
  map⁻-cong {z ∷ zs} (hereEq {x = x} {y} px py x≈z y≈z) =
    hereEq (transport B P px x≈z) (transport B P py y≈z) (refl A) (refl A)
  map⁻-cong {z ∷ zs} (thereEq i∼j) = thereEq (map⁻-cong i∼j)
\end{code}
%}}}

%{{{ \subsection{FindLose}
\subsection{FindLose}

\begin{code}
module FindLose {a ℓa : Level} {A : Setoid a ℓa}  (P : A ⟶ SSetoid ℓa ℓa) where
  open Membership A
  open Setoid A
  open Π
  open _≅_
  private
    P₀ = λ e → Setoid.Carrier (Π._⟨$⟩_ P e)
    Support = λ ys → Σ y ∶ Carrier • y ∈₀ ys × P₀ y

  find : {ys : List Carrier} → Some₀ {S = A} P₀ ys → Support ys
  find {y ∷ ys} (here {a} a≈y p) = a , here a≈y (sym a≈y) , transport P p a≈y
  find {y ∷ ys} (there p) =  let (a , a∈ys , Pa) = find p
                             in a , there a∈ys , Pa

  lose : {ys : List Carrier} → Support ys → Some₀ {S = A} P₀ ys
  lose (y , here b≈y py , Py)  = here b≈y (Equivalence.to (Π.cong P py) Π.⟨$⟩ Py)
  lose (y , there {b} y∈ys , Py)   = there (lose (y , y∈ys , Py))
\end{code}
%}}}

%{{{ \subsection{Σ-Setoid}
\subsection{Σ-Setoid}

\edcomm{WK}{Abstruse name!}
\edcomm{JC}{Feel free to rename.  I agree that it is not a good name.  I was more
concerned with the semantics, and then could come back to clean up once it worked.}

This is an ``unpacked'' version of |Some|, where each piece (see |Support| below) is
separated out.  For some equivalences, it seems to work with this representation.

\begin{code}
module _ {ℓs ℓS : Level} {A : Setoid ℓs ℓS} {P : A ⟶ SSetoid ℓS ℓS} where
  open Membership A
  open Setoid A
  private
    P₀ = λ e → Setoid.Carrier (Π._⟨$⟩_ P e)
    Support = λ ys → Σ y ∶ Carrier • y ∈₀ ys × P₀ y
    squish : {x y : Setoid.Carrier A} → P₀ x → P₀ y → Set ℓs
    squish _ _ = ⊤

  -- FIXME : this definition is still not right
  _∻_ : {ys : List Carrier} → Support ys → Support ys → Set (ℓs ⊔ ℓS)
  (a , a∈xs , Pa) ∻ (b , b∈xs , Pb) =
    Σ (a ≈ b) (λ a≈b → ∈₀-subst₁ a≈b a∈xs ≋ b∈xs × squish Pa Pb)

  Σ-Setoid : (ys : List Carrier) → Setoid (ℓS ⊔ ℓs) (ℓS ⊔ ℓs)
  Σ-Setoid [] = ⊥⊥
  Σ-Setoid (y ∷ ys) = record
    { Carrier = Support (y ∷ ys)
    ; _≈_ = _∻_
    ; isEquivalence = record
      { refl = λ {s} → Refl {s}
      ; sym = λ {s} {t} eq → Sym {s} {t} eq
      ; trans = λ {s} {t} {u} a b → Trans {s} {t} {u} a b
      }
    }
    where
      Refl : Reflexive _∻_
      Refl {a₁ , here sm px , Pa} = refl , hereEq (trans (sym refl) px) px sm sm , tt
      Refl {a₁ , there a∈xs , Pa} = refl , thereEq (∈₀-subst₁-elim a∈xs) , tt

      Sym  : Symmetric _∻_
      Sym (a≈b , a∈xs≋b∈xs , Pa≈Pb) = sym a≈b , ∈₀-subst₁-sym a∈xs≋b∈xs , tt

      Trans : Transitive _∻_
      Trans (a≈b , a∈xs≋b∈xs , Pa≈Pb) (b≈c , b∈xs≋c∈xs , Pb≈Pc) = trans a≈b b≈c , ∈₀-subst₁-trans a∈xs≋b∈xs b∈xs≋c∈xs , tt

  module ∻ {ys} where open Setoid (Σ-Setoid ys) public

  open FindLose P

  find-cong : {xs : List Carrier} {p q : Some₀ P₀ xs} → p ≋ q → find p ∻ find q
  find-cong {p = .(here x≈z px)} {.(here y≈z qy)} (hereEq px qy x≈z y≈z) =
    refl , hereEq (trans (sym refl) (sym x≈z)) (sym y≈z) x≈z y≈z , tt
  find-cong {p = .(there _)} {.(there _)} (thereEq p≋q) =
    proj₁ (find-cong p≋q) , thereEq (proj₁ (proj₂ (find-cong p≋q))) , proj₂ (proj₂ (find-cong p≋q))

  forget-cong : {xs : List Carrier} {i j : Support xs } → i ∻ j → lose i ≋ lose j
  forget-cong {i = a₁ , here sm px , Pa} {b , here sm₁ px₁ , Pb} (i≈j , a∈xs≋b∈xs) =
    hereEq (transport P Pa px) (transport P Pb px₁) sm sm₁
  forget-cong {i = a₁ , here sm px , Pa} {b , there b∈xs , Pb} (i≈j , () , _)
  forget-cong {i = a₁ , there a∈xs , Pa} {b , here sm px , Pb} (i≈j , () , _)
  forget-cong {i = a₁ , there a∈xs , Pa} {b , there b∈xs , Pb} (i≈j , thereEq pf , Pa≈Pb) =
    thereEq (forget-cong (i≈j , pf , Pa≈Pb))

  left-inv : {zs : List Carrier} (x∈zs : Some₀ P₀ zs) → lose (find x∈zs) ≋ x∈zs
  left-inv (here {a} {x} a≈x px) = hereEq (transport P (transport P px a≈x) (sym a≈x)) px a≈x a≈x
  left-inv (there x∈ys) = thereEq (left-inv x∈ys)

  right-inv : {ys : List Carrier} (pf : Σ y ∶ Carrier • y ∈₀ ys × P₀ y) → find (lose pf) ∻ pf
  right-inv (y , here a≈x px , Py) = trans (sym a≈x) (sym px) , hereEq (trans (sym (trans (sym a≈x) (sym px))) (sym a≈x)) px a≈x a≈x , tt
  right-inv (y , there y∈ys , Py) =
    let (α₁ , α₂ , α₃) = right-inv (y , y∈ys , Py) in
    (α₁ , thereEq α₂ , α₃)
    -- (proj₁ (right-inv (y , y∈ys , Py))) , (thereEq (proj₁ (proj₂ (right-inv (y , y∈ys , Py))))) , {!proj₂ (proj₂ (right-inv!}

  Σ-Some : (xs : List Carrier) → Some P xs ≅ Σ-Setoid xs
  Σ-Some [] = ≅-sym (⊥≅Some[] {ℓs} {ℓS} {A} {P})
  Σ-Some (x ∷ xs) =  record
    { to = record { _⟨$⟩_ = find ; cong = find-cong }
    ; from = record { _⟨$⟩_ = lose ; cong = forget-cong }
    ; inverse-of = record
      { left-inverse-of = left-inv
      ; right-inverse-of = right-inv
      }
    }

  Σ-cong : {xs ys : List Carrier} → BagEq xs ys → Σ-Setoid xs ≅ Σ-Setoid ys
  Σ-cong {[]} {[]} iso = ≅-refl
  Σ-cong {[]} {z ∷ zs} iso = ⊥-elim (_≅_.from (⊥≅Some[] {A = A} {setoid≈ z}) ⟨$⟩ (_≅_.from iso ⟨$⟩ here refl refl))
  Σ-cong {x ∷ xs} {[]} iso = ⊥-elim (_≅_.from (⊥≅Some[] {A = A} {setoid≈ x}) ⟨$⟩ (_≅_.to iso ⟨$⟩ here refl refl))
  Σ-cong {x ∷ xs} {y ∷ ys} xs≅ys = record
    { to   = record { _⟨$⟩_ = xs→ys xs≅ys         ; cong = λ {i j} → xs→ys-cong xs≅ys {i} {j} }
    ; from = record { _⟨$⟩_ = xs→ys (≅-sym xs≅ys) ; cong = λ {i j} → xs→ys-cong (≅-sym xs≅ys) {i} {j} }
    ; inverse-of = record
      { left-inverse-of = λ { (z , z∈xs , Pz) → refl , (≋-trans (∈₀-subst₁-elim _) (left-inverse-of xs≅ys z∈xs) , tt) }
      ; right-inverse-of = λ { (z , z∈ys , Pz) → refl , ≋-trans (∈₀-subst₁-elim _) (right-inverse-of xs≅ys z∈ys) , tt }
      }
    }
    where
      open _≅_
      xs→ys : {zs ws : List Carrier} → BagEq zs ws → Support zs → Support ws
      xs→ys eq (a , a∈xs , Pa) = (a , ∈₀-subst₂ eq a∈xs , Pa)

      --  ∈₀-subst₁-equiv  : x ≈ y → (x ∈ xs) ≅ (y ∈ xs)
      xs→ys-cong : {zs ws : List Carrier} (eq : BagEq zs ws) {i j : Support zs} →
        i ∻ j → xs→ys eq i ∻ xs→ys eq j
      xs→ys-cong eq {_ , a∈zs , _} {_ , b∈zs , _} (a≈b , pf , Pa≈Pb) =
        a≈b , {!!} , tt
\end{code}
%}}}

%{{{ \subsection{Some-cong} (∀ {x} → x ∈ xs₁ ≅ x ∈ xs₂) → Some P xs₁ ≅ Some P xs₂
\subsection{Some-cong}
This isn't quite the full-powered cong, but is all we need.

\edcomm{WK}{It has position preservation neither in the assumption (|list-rel|),
nor in the conclusion. Why did you bother with position preservation for |_≋_|?}
\edcomm{JC}{Because |_≋_| is about showing that two positions \emph{in the same
list} are equivalent.  And |list-rel| is a permutation between two lists.
I agree that |_≋_| could be ``loosened'' to be up to
permutation of elements which are |_≈_| to a given one.

But if our notion of permutation is |BagEq|, which depends on |_∈_|, which
depends on |Some|, which depends on |_≋_|. If that now depends on |BagEq|,
we've got a mutual recursion that seems unecessary.}

\begin{code}
module _ {a ℓa : Level} {A : Setoid a ℓa} {P : A ⟶ SSetoid ℓa ℓa} where

  open Membership A
  open Setoid A
  private P₀ = λ e → (Π._⟨$⟩_ P e)

  Some-cong : {xs₁ xs₂ : List Carrier} →
            (∀ {x} → (x ∈ xs₁) ≅ (x ∈ xs₂)) →
            Some P xs₁ ≅ Some P xs₂
  Some-cong {xs₁} {xs₂} xs₁≅xs₂ =
    Some P xs₁             ≅⟨ Σ-Some xs₁ ⟩
    Σ-Setoid {P = P} xs₁   ≅⟨ Σ-cong xs₁≅xs₂ ⟩
    Σ-Setoid {P = P} xs₂   ≅⟨ ≅-sym (Σ-Some xs₂) ⟩
    Some P xs₂ ∎
\end{code}

%}}}

% Quick Folding Instructions:
% C-c C-s :: show/unfold region
% C-c C-h :: hide/fold region
% C-c C-w :: whole file fold
% C-c C-o :: whole file unfold
%
% Local Variables:
% folded-file: t
% eval: (fold-set-marks "%{{{ " "%}}}")
% eval: (fold-whole-buffer)
% fold-internal-margins: 0
% end:

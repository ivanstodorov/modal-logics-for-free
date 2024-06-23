{-# OPTIONS --without-K --safe --guardedness #-}
module ModalLogics.RegularFormulas.Base where

open import Common.Program using (Program)
open import Common.RegularFormulas using (ActionFormula; RegularFormula)
open import Data.Bool using (true; false)
open import Data.Container using (Container)
open import Data.Fin using (Fin; toℕ; inject₁)
open import Data.List using (List; length; findIndexᵇ)
open import Data.Maybe using (just; nothing)
open import Data.Nat using (ℕ; suc; _<ᵇ_)
open import Data.String using (String; _==_)
open import Level using (Level; _⊔_)
open import ModalLogics.FixedPoints.Base using (Formulaⁱ; _⊨ⁱ_)

open RegularFormula
open Fin
open List
open Formulaⁱ

private variable
  ℓ₁ ℓ₂ ℓ₃ : Level

infix 60 ref_
infix 55 ~_
infix 50 ⟨_⟩_
infix 50 [_]_
infixr 45 _∧_
infixr 40 _∨_
infixr 35 _⇒_
infix 30 μ_．_
infix 30 ν_．_

data Formula (C : Container ℓ₁ ℓ₂) : Set ℓ₁ where
  true false : Formula C
  ~_ : Formula C → Formula C
  _∧_ _∨_ _⇒_ : Formula C → Formula C → Formula C
  ⟨_⟩_ [_]_ : RegularFormula C → Formula C → Formula C
  μ_．_ ν_．_ : String → Formula C → Formula C
  ref_ : String → Formula C

infix 25 _⊨_

_⊨_ : {C : Container ℓ₁ ℓ₂} → {α : Set ℓ₃} → Program C α → Formula C → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
x ⊨ f = x ⊨ⁱ f→fⁱ f []
  where
  infix 80 actF'_
  infix 75 _*'
  infixr 70 _·'_
  infixr 65 _+'_

  data RegularFormula' (C : Container ℓ₁ ℓ₂) : Set ℓ₁ where
    ε' : RegularFormula' C
    actF'_ : ActionFormula C → RegularFormula' C
    _·'_ _+'_ : RegularFormula' C → RegularFormula' C → RegularFormula' C
    _*' : RegularFormula' C → RegularFormula' C

  rf→rf' : {C : Container ℓ₁ ℓ₂} → RegularFormula C → RegularFormula' C
  rf→rf' ε = ε'
  rf→rf' (actF af) = actF' af
  rf→rf' (rf₁ · rf₂) = rf→rf' rf₁ ·' rf→rf' rf₂
  rf→rf' (rf₁ + rf₂) = rf→rf' rf₁ +' rf→rf' rf₂
  rf→rf' (rf *) = rf→rf' rf *'
  rf→rf' (rf ⁺) = rf' ·' (rf' *')
    where
    rf' = rf→rf' rf

  ref⁺ : {C : Container ℓ₁ ℓ₂} → {n : ℕ} → Formulaⁱ C n → Formulaⁱ C (suc n)
  ref⁺ fⁱ = ref⁺' fⁱ zero
    where
    ref⁺' : {C : Container ℓ₁ ℓ₂} → {n : ℕ} → Formulaⁱ C n → Fin (suc n) → Formulaⁱ C (suc n)
    ref⁺' trueⁱ _ = trueⁱ
    ref⁺' falseⁱ _ = falseⁱ
    ref⁺' (~ⁱ fⁱ) x = ~ⁱ ref⁺' fⁱ x
    ref⁺' (fⁱ₁ ∧ⁱ fⁱ₂) x = ref⁺' fⁱ₁ x ∧ⁱ ref⁺' fⁱ₂ x
    ref⁺' (fⁱ₁ ∨ⁱ fⁱ₂) x = ref⁺' fⁱ₁ x ∨ⁱ ref⁺' fⁱ₂ x
    ref⁺' (fⁱ₁ ⇒ⁱ fⁱ₂) x = ref⁺' fⁱ₁ x ⇒ⁱ ref⁺' fⁱ₂ x
    ref⁺' (⟨ af ⟩ⁱ fⁱ) x = ⟨ af ⟩ⁱ ref⁺' fⁱ x
    ref⁺' ([ af ]ⁱ fⁱ) x = [ af ]ⁱ ref⁺' fⁱ x
    ref⁺' (μⁱ fⁱ) x = μⁱ ref⁺' fⁱ (suc x)
    ref⁺' (νⁱ fⁱ) x = νⁱ ref⁺' fⁱ (suc x)
    ref⁺' (refⁱ i) x with toℕ i <ᵇ toℕ x
    ... | false = refⁱ suc i
    ... | true = refⁱ inject₁ i

  f→fⁱ : {C : Container ℓ₁ ℓ₂} → Formula C → (xs : List String) → Formulaⁱ C (length xs)
  f→fⁱ true _ = trueⁱ
  f→fⁱ false _ = falseⁱ
  f→fⁱ (~ f) xs = ~ⁱ f→fⁱ f xs
  f→fⁱ (f₁ ∧ f₂) xs = f→fⁱ f₁ xs ∧ⁱ f→fⁱ f₂ xs
  f→fⁱ (f₁ ∨ f₂) xs = f→fⁱ f₁ xs ∨ⁱ f→fⁱ f₂ xs
  f→fⁱ (f₁ ⇒ f₂) xs = f→fⁱ f₁ xs ⇒ⁱ f→fⁱ f₂ xs
  f→fⁱ (⟨ rf ⟩ f) xs = helper-∃ (rf→rf' rf) (f→fⁱ f xs)
    where
    helper-∃ : {C : Container ℓ₁ ℓ₂} → {n : ℕ} → RegularFormula' C → Formulaⁱ C n → Formulaⁱ C n
    helper-∃ ε' fⁱ = fⁱ
    helper-∃ (actF' af) fⁱ = ⟨ af ⟩ⁱ fⁱ
    helper-∃ (rf⁺₁ ·' rf⁺₂) fⁱ = helper-∃ rf⁺₁ (helper-∃ rf⁺₂ fⁱ)
    helper-∃ (rf⁺₁ +' rf⁺₂) fⁱ = helper-∃ rf⁺₁ fⁱ ∨ⁱ helper-∃ rf⁺₂ fⁱ
    helper-∃ (rf⁺ *') fⁱ = μⁱ helper-∃ rf⁺ (refⁱ zero) ∨ⁱ ref⁺ fⁱ
  f→fⁱ ([ rf ] f) xs = helper-∀ (rf→rf' rf) (f→fⁱ f xs)
    where
    helper-∀ : {C : Container ℓ₁ ℓ₂} → {n : ℕ} → RegularFormula' C → Formulaⁱ C n → Formulaⁱ C n
    helper-∀ ε' fⁱ = fⁱ
    helper-∀ (actF' af) fⁱ = [ af ]ⁱ fⁱ
    helper-∀ (rf⁺₁ ·' rf⁺₂) fⁱ = helper-∀ rf⁺₁ (helper-∀ rf⁺₂ fⁱ)
    helper-∀ (rf⁺₁ +' rf⁺₂) fⁱ = helper-∀ rf⁺₁ fⁱ ∨ⁱ helper-∀ rf⁺₂ fⁱ
    helper-∀ (rf⁺ *') fⁱ = νⁱ helper-∀ rf⁺ (refⁱ zero) ∧ⁱ ref⁺ fⁱ
  f→fⁱ (μ x ． f) xs = μⁱ f→fⁱ f (x ∷ xs)
  f→fⁱ (ν x ． f) xs = νⁱ f→fⁱ f (x ∷ xs)
  f→fⁱ (ref x) xs with findIndexᵇ (_==_ x) xs
  ... | just i = refⁱ i
  ... | nothing = falseⁱ

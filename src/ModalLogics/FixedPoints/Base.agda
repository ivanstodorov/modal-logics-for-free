{-# OPTIONS --without-K --safe --guardedness #-}
module ModalLogics.FixedPoints.Base where

open import Common.RegularFormulas using (ActionFormula; _⊩ᵃᶠ_)
open import Common.Program using (Program; RecursiveProgram; recursionHandler)
open import Data.Bool using (Bool; not)
open import Data.Container using () renaming (Container to Containerˢᵗᵈ)
open import Data.Container.FreeMonad using (_⋆_)
open import Data.Empty.Polymorphic using (⊥)
open import Data.Fin using (Fin; _≟_; toℕ)
open import Data.List using (List; length; findIndexᵇ) renaming (lookup to lookup')
open import Data.List.NonEmpty using (List⁺; [_]; _∷⁺_; foldr; toList) renaming (length to length⁺)
open import Data.Maybe using (just; nothing)
open import Data.Nat using (ℕ; _∸_)
open import Data.Product using (_×_; _,_; ∃-syntax)
open import Data.String using (String; _==_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit.Polymorphic using (⊤)
open import Level using (Level; _⊔_)
open import Relation.Binary.PropositionalEquality using (_≡_; subst)
open import Relation.Binary.Structures using (IsDecEquivalence)
open import Relation.Nullary using (yes; no)

open Bool
open Containerˢᵗᵈ renaming (Shape to Shapeˢᵗᵈ; Position to Positionˢᵗᵈ)
open _⋆_
open Fin
open List
open ℕ
open _≡_

private variable
  ℓ ℓ₁ ℓ₂ ℓ₃ ℓ₄ : Level

data Formulaᵈⁿᶠ-var (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁
data Formulaᵈⁿᶠ-con (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁
data Formulaᵈⁿᶠ-dis (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁

infix 55 refᵈⁿᶠ_
infix 50 ⟨_⟩ᵈⁿᶠ_
infix 50 [_]ᵈⁿᶠ_
infix 50 μᵈⁿᶠ_
infix 50 νᵈⁿᶠ_

data Formulaᵈⁿᶠ-var C where
  trueᵈⁿᶠ falseᵈⁿᶠ : ∀ {n} → Formulaᵈⁿᶠ-var C n
  ⟨_⟩ᵈⁿᶠ_ [_]ᵈⁿᶠ_ : ∀ {n} → ActionFormula C → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-var C n
  μᵈⁿᶠ_ νᵈⁿᶠ_ : ∀ {n} → Formulaᵈⁿᶠ-dis C (suc n) → Formulaᵈⁿᶠ-var C n
  refᵈⁿᶠ_ : ∀ {n} → Fin n → Formulaᵈⁿᶠ-var C n

infix 45 con-var_
infixr 40 _∧ᵈⁿᶠ_

data Formulaᵈⁿᶠ-con C where
  con-var_ : ∀ {n} → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-con C n
  _∧ᵈⁿᶠ_ : ∀ {n} → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n

infix 35 dis-con_
infixr 30 _∨ᵈⁿᶠ_

data Formulaᵈⁿᶠ-dis C where
  dis-con_ : ∀ {n} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-dis C n
  _∨ᵈⁿᶠ_ : ∀ {n} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n

data FixedPoint : Set where
  leastFP : FixedPoint
  greatestFP : FixedPoint

data Previous (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set (ℓ₁ ⊔ ℓ₂) where
  〔_〕 : FixedPoint × Formulaᵈⁿᶠ-dis C (suc zero) → Previous C (suc zero)
  _∷_ : ∀ {n} → FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) → Previous C n → Previous C (suc n)

lookup : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Previous C n → (i : Fin n) → FixedPoint × Formulaᵈⁿᶠ-dis C (n ∸ toℕ i) × Previous C (n ∸ toℕ i)
lookup prev@(〔 fp , C 〕) zero = fp , C , prev
lookup prev@((fp , C) ∷ _) zero = fp , C , prev
lookup (_ ∷ prev) (suc i) = lookup prev i

data Maybe' (α : Set ℓ) : Set ℓ where
  val_ : α → Maybe' α
  done : Maybe' α
  fail : Maybe' α

data Result (C : Containerˢᵗᵈ ℓ₁ ℓ₂) (α : Set ℓ₃) (n : ℕ) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃) where
  res_ : Maybe' ((C ⋆ α) × (Fin n × Previous C n ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n))) → Result C α n
  ∃〔_〕_ : (s : Shapeˢᵗᵈ C) → (Positionˢᵗᵈ C s → Result C α n) → Result C α n
  ∀〔_〕_ : (s : Shapeˢᵗᵈ C) → (Positionˢᵗᵈ C s → Result C α n) → Result C α n

unfold : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {α : Set ℓ₃} → {n : ℕ} → Result C α n → Maybe' ((C ⋆ α) × (Fin n × Previous C n ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n))) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
unfold (res v) o = o ≡ v
unfold (∃〔 _ 〕 c) o = ∃[ p ] unfold (c p) o
unfold (∀〔 _ 〕 c) o = ∀ p → unfold (c p) o

record Container (C : Containerˢᵗᵈ ℓ₁ ℓ₂) (α : Set ℓ₃) (n : ℕ) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃) where
  constructor _▷_
  field
    Shape : ℕ
    Position : Fin Shape → C ⋆ α → List⁺ (Result C α n)

open Container

data ModalitySequence (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : Set ℓ₁ where
  ⟪_⟫_ ⟦_⟧_ : ActionFormula C → ModalitySequence C → ModalitySequence C
  ε : ModalitySequence C

apply : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ _ : IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → {n : ℕ} → ModalitySequence C → C ⋆ α → (Maybe' (C ⋆ α) → Result C α n) → Result C α n
apply (⟪ _ ⟫ _) (pure _) f = f fail
apply (⟪ af ⟫ m) (impure (s , c)) f with af ⊩ᵃᶠ s
... | false = f fail
... | true = ∃〔 s 〕 λ p → apply m (c p) f
apply (⟦ _ ⟧ _) (pure _) f = f done
apply (⟦ af ⟧ m) (impure (s , c)) f with af ⊩ᵃᶠ s
... | false = f done
... | true = ∀〔 s 〕 λ p → apply m (c p) f
apply ε x f = f (val x)

containerize-var : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {n : ℕ} → Formulaᵈⁿᶠ-var C (suc n) → Previous C (suc n) → ModalitySequence C × Maybe' (Fin (suc n) × Previous C (suc n) ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc (suc n)) × Previous C (suc (suc n)))
containerize-var trueᵈⁿᶠ _ = ε , done
containerize-var falseᵈⁿᶠ _ = ε , fail
containerize-var (⟨ af ⟩ᵈⁿᶠ v) prev with containerize-var v prev
... | m , x = ⟪ af ⟫ m , x
containerize-var ([ af ]ᵈⁿᶠ v) prev with containerize-var v prev
... | m , x = ⟦ af ⟧ m , x
containerize-var (μᵈⁿᶠ d) prev = ε , val inj₂ (leastFP , d , ((leastFP , d) ∷ prev))
containerize-var (νᵈⁿᶠ d) prev = ε , val inj₂ (greatestFP , d , (greatestFP , d) ∷ prev)
containerize-var (refᵈⁿᶠ i) prev = ε , val inj₁ (i , prev)

containerize-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {n : ℕ} → Formulaᵈⁿᶠ-con C (suc n) → Previous C (suc n) → List⁺ (ModalitySequence C × Maybe' (Fin (suc n) × Previous C (suc n) ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc (suc n)) × Previous C (suc (suc n))))
containerize-con (con-var v) prev = [ containerize-var v prev ]
containerize-con (v ∧ᵈⁿᶠ c) prev = containerize-var v prev ∷⁺ containerize-con c prev

containerize-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {n : ℕ} → Formulaᵈⁿᶠ-dis C (suc n) → Previous C (suc n) → List⁺ (List⁺ (ModalitySequence C × Maybe' (Fin (suc n) × Previous C (suc n) ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc (suc n)) × Previous C (suc (suc n)))))
containerize-dis (dis-con c) prev = [ containerize-con c prev ]
containerize-dis (c ∨ᵈⁿᶠ d) prev = containerize-con c prev ∷⁺ containerize-dis d prev

containerize : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {n : ℕ} → Formulaᵈⁿᶠ-dis C (suc n) → Previous C (suc n) → (α : Set ℓ₃) → Container C α (suc n)
containerize {C = C} {n = n} d prev α with containerize-dis d prev
... | xs = container
  where
  container : Container C α (suc n)
  Shape container = length⁺ xs
  Position container s i = foldr (λ (m , x) acc → position m i x ∷⁺ acc) (λ (m , x) → [ position m i x ]) (lookup' (toList xs) s)
    where
    position : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → {n : ℕ} → ModalitySequence C → C ⋆ α → Maybe' (Fin n × Previous C n ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)) → Result C α n
    position m i (val x) = apply m i λ { (val o) → res (val (o , x)) ; done → res done ; fail → res fail }
    position m i done = apply m i λ { (val _) → res done ; done → res done ; fail → res fail }
    position m i fail = apply m i λ { (val _) → res fail ; done → res done ; fail → res fail }

n∸fin[n]≡suc : (n : ℕ) → (i : Fin n) → ∃[ x ] n ∸ toℕ i ≡ suc x
n∸fin[n]≡suc (suc n) zero = n , refl
n∸fin[n]≡suc (suc n) (suc i) = n∸fin[n]≡suc n i

extend : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → {n : ℕ} → Maybe' ((C ⋆ α) × ((Fin n × Previous C n) ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n))) → (∀ {n} → Maybe' ((C ⋆ α) × ((Fin n × Previous C n) ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n))) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)) → (∀ {n} → Maybe' ((C ⋆ α) × ((Fin n × Previous C n) ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n))) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)) → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
extend {C = C} {α = α} {n = n} (val (x , inj₁ (i , prev))) w m with n∸fin[n]≡suc n i
... | n₁ , h with lookup prev i
...   | fp , d , prev₁ with subst (Formulaᵈⁿᶠ-dis C) h d | subst (Previous C) h prev₁
extend {C = C} {α = α} {n = n} (val (x , inj₁ (i , prev))) w m | n₁ , h | leastFP , d , prev₁ | d₁ | prev₂ = ∃[ s ] ∀ {i} → foldr (λ r acc → unfold r i ⊎ acc) (λ r → unfold r i) (Position (containerize d₁ prev₂ α) s x) → w i
extend {C = C} {α = α} {n = n} (val (x , inj₁ (i , prev))) w m | n₁ , h | greatestFP , d , prev₁ | d₁ | prev₂ = ∃[ s ] ∀ {i} → foldr (λ r acc → unfold r i ⊎ acc) (λ r → unfold r i) (Position (containerize d₁ prev₂ α) s x) → m i
extend {α = α} (val (x , inj₂ (leastFP , d , prev))) w _ = ∃[ s ] ∀ {i} → foldr (λ r acc → unfold r i ⊎ acc) (λ r → unfold r i) (Position (containerize d prev α) s x) → w i
extend {α = α} (val (x , inj₂ (greatestFP , d , prev))) _ m = ∃[ s ] ∀ {i} → foldr (λ r acc → unfold r i ⊎ acc) (λ r → unfold r i) (Position (containerize d prev α) s x) → m i
extend done _ _ = ⊤
extend fail _ _ = ⊥

record WI {C : Containerˢᵗᵈ ℓ₁ ℓ₂} ⦃ _ : IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ {α : Set ℓ₃} {n : ℕ} (_ : Maybe' ((C ⋆ α) × (Fin n × Previous C n ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)))) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
record MI {C : Containerˢᵗᵈ ℓ₁ ℓ₂} ⦃ _ : IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ {α : Set ℓ₃} {n : ℕ} (_ : Maybe' ((C ⋆ α) × (Fin n × Previous C n ⊎ FixedPoint × Formulaᵈⁿᶠ-dis C (suc n) × Previous C (suc n)))) : Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)

record WI i where
  inductive
  constructor wi
  field
    In : extend i WI MI

record MI i where
  coinductive
  constructor mi
  field
    Ni : extend i WI MI

infix 25 _⊩ᵛ_

_⊩ᵛ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → Formulaᵈⁿᶠ-var C zero → C ⋆ α → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
trueᵈⁿᶠ ⊩ᵛ _ = ⊤
falseᵈⁿᶠ ⊩ᵛ _ = ⊥
⟨ _ ⟩ᵈⁿᶠ _ ⊩ᵛ pure _ = ⊥
⟨ af ⟩ᵈⁿᶠ v ⊩ᵛ impure (s , c) with af ⊩ᵃᶠ s
... | false = ⊥
... | true = ∃[ p ] v ⊩ᵛ c p
[ _ ]ᵈⁿᶠ _ ⊩ᵛ pure _ = ⊤
[ af ]ᵈⁿᶠ v ⊩ᵛ impure (s , c) with af ⊩ᵃᶠ s
... | false = ⊤
... | true = ∀ p → v ⊩ᵛ c p
μᵈⁿᶠ d ⊩ᵛ x = WI (val (x , inj₂ (leastFP , d , 〔 leastFP , d 〕)))
νᵈⁿᶠ d ⊩ᵛ x = MI (val (x , inj₂ (greatestFP , d , 〔 greatestFP , d 〕)))

infix 25 _⊩ᶜ_

_⊩ᶜ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → Formulaᵈⁿᶠ-con C zero → C ⋆ α → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
con-var v ⊩ᶜ x = v ⊩ᵛ x
v ∧ᵈⁿᶠ c ⊩ᶜ x = (v ⊩ᵛ x) × (c ⊩ᶜ x)

infix 25 _⊩ᵈ_

_⊩ᵈ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → Formulaᵈⁿᶠ-dis C zero → C ⋆ α → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
dis-con c ⊩ᵈ x = c ⊩ᶜ x
c ∨ᵈⁿᶠ d ⊩ᵈ x = (c ⊩ᶜ x) ⊎ (d ⊩ᵈ x)

infix 45 refⁱ_
infix 40 ¬ⁱ_
infixr 35 _∧ⁱ_
infixr 35 _∨ⁱ_
infixr 35 _⇒ⁱ_
infix 30 ⟨_⟩ⁱ_
infix 30 [_]ⁱ_
infix 30 μⁱ_
infix 30 νⁱ_

data Formulaⁱ (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁ where
  trueⁱ falseⁱ : ∀ {n} → Formulaⁱ C n
  ¬ⁱ_ : ∀ {n} → Formulaⁱ C n → Formulaⁱ C n
  _∧ⁱ_ _∨ⁱ_ _⇒ⁱ_ : ∀ {n} → Formulaⁱ C n → Formulaⁱ C n → Formulaⁱ C n
  ⟨_⟩ⁱ_ [_]ⁱ_ : ∀ {n} → ActionFormula C → Formulaⁱ C n → Formulaⁱ C n
  μⁱ_ νⁱ_ : ∀ {n} → Formulaⁱ C (suc n) → Formulaⁱ C n
  refⁱ_ : ∀ {n} → Fin n → Formulaⁱ C n

infix 25 _⊩ⁱ_

_⊩ⁱ_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → Formulaⁱ C zero → C ⋆ α → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
fⁱ ⊩ⁱ x = f'→fᵈⁿᶠ (fⁱ→f' fⁱ) ⊩ᵈ x
  where
  infix 45 ref'〔_〕_
  infixr 35 _∧'_
  infixr 35 _∨'_
  infix 30 ⟨_⟩'_
  infix 30 [_]'_
  infix 30 μ'_
  infix 30 ν'_

  data Formula' (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : ℕ → Set ℓ₁ where
    true' false' : ∀ {n} → Formula' C n
    _∧'_ _∨'_ : ∀ {n} → Formula' C n → Formula' C n → Formula' C n
    ⟨_⟩'_ [_]'_ : ∀ {n} → ActionFormula C → Formula' C n → Formula' C n
    μ'_ ν'_ : ∀ {n} → Formula' C (suc n) → Formula' C n
    ref'〔_〕_ : ∀ {n} → Bool → Fin n → Formula' C n

  flipRef : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Fin n → Formula' C n → Formula' C n
  flipRef _ true' = true'
  flipRef _ false' = false'
  flipRef x (f'₁ ∧' f'₂) = flipRef x f'₁ ∧' flipRef x f'₂
  flipRef x (f'₁ ∨' f'₂) = flipRef x f'₁ ∨' flipRef x f'₂
  flipRef x (⟨ af ⟩' f') = ⟨ af ⟩' flipRef x f'
  flipRef x ([ af ]' f') = [ af ]' flipRef x f'
  flipRef x (μ' f') = μ' flipRef (suc x) f'
  flipRef x (ν' f') = ν' flipRef (suc x) f'
  flipRef x (ref'〔 b 〕 i) with i ≟ x
  ... | no _ = ref'〔 b 〕 i
  ... | yes _ = ref'〔 not b 〕 i

  negate : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formula' C n → Formula' C n
  negate true' = false'
  negate false' = true'
  negate (f'₁ ∧' f'₂) = negate f'₁ ∨' negate f'₂
  negate (f'₁ ∨' f'₂) = negate f'₁ ∧' negate f'₂
  negate (⟨ af ⟩' f') = [ af ]' negate f'
  negate ([ af ]' f') = ⟨ af ⟩' negate f'
  negate (μ' f') = ν' flipRef zero f'
  negate (ν' f') = μ' flipRef zero f'
  negate (ref'〔 b 〕 i) = ref'〔 not b 〕 i

  fⁱ→f' : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaⁱ C n → Formula' C n
  fⁱ→f' trueⁱ = true'
  fⁱ→f' falseⁱ = false'
  fⁱ→f' (¬ⁱ fⁱ) = negate (fⁱ→f' fⁱ)
  fⁱ→f' (fⁱ₁ ∧ⁱ fⁱ₂) = fⁱ→f' fⁱ₁ ∧' fⁱ→f' fⁱ₂
  fⁱ→f' (fⁱ₁ ∨ⁱ fⁱ₂) = fⁱ→f' fⁱ₁ ∨' fⁱ→f' fⁱ₂
  fⁱ→f' (fⁱ₁ ⇒ⁱ fⁱ₂) = negate (fⁱ→f' fⁱ₁) ∨' fⁱ→f' fⁱ₂
  fⁱ→f' (⟨ af ⟩ⁱ fⁱ) = ⟨ af ⟩' fⁱ→f' fⁱ
  fⁱ→f' ([ af ]ⁱ fⁱ) = [ af ]' fⁱ→f' fⁱ
  fⁱ→f' (μⁱ fⁱ) = μ' fⁱ→f' fⁱ
  fⁱ→f' (νⁱ fⁱ) = ν' fⁱ→f' fⁱ
  fⁱ→f' (refⁱ i) = ref'〔 true 〕 i

  merge-dis-dis-or : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
  merge-dis-dis-or (dis-con c) d = c ∨ᵈⁿᶠ d
  merge-dis-dis-or (c ∨ᵈⁿᶠ d₁) d₂ = c ∨ᵈⁿᶠ merge-dis-dis-or d₁ d₂

  merge-con-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n
  merge-con-con (con-var v) c = v ∧ᵈⁿᶠ c
  merge-con-con (v ∧ᵈⁿᶠ c₁) c₂ = v ∧ᵈⁿᶠ merge-con-con c₁ c₂

  merge-con-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
  merge-con-dis c₁ (dis-con c₂) = dis-con (merge-con-con c₁ c₂)
  merge-con-dis c₁ (c₂ ∨ᵈⁿᶠ d₂) = merge-con-con c₁ c₂ ∨ᵈⁿᶠ merge-con-dis c₁ d₂

  merge-dis-dis-and : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
  merge-dis-dis-and (dis-con c) d = merge-con-dis c d
  merge-dis-dis-and (c ∨ᵈⁿᶠ d₁) d₂ = merge-dis-dis-or (merge-con-dis c d₂) (merge-dis-dis-and d₁ d₂)

  f'→fᵈⁿᶠ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → Formula' C n → Formulaᵈⁿᶠ-dis C n
  f'→fᵈⁿᶠ true' = dis-con (con-var trueᵈⁿᶠ)
  f'→fᵈⁿᶠ false' = dis-con (con-var falseᵈⁿᶠ)
  f'→fᵈⁿᶠ (f'₁ ∧' f'₂) = merge-dis-dis-and (f'→fᵈⁿᶠ f'₁) (f'→fᵈⁿᶠ f'₂)
  f'→fᵈⁿᶠ (f'₁ ∨' f'₂) = merge-dis-dis-or (f'→fᵈⁿᶠ f'₁) (f'→fᵈⁿᶠ f'₂)
  f'→fᵈⁿᶠ (⟨ af ⟩' f') = merge-∃-dis af (f'→fᵈⁿᶠ f')
    where
    merge-∃-var : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-var C n
    merge-∃-var af v = ⟨ af ⟩ᵈⁿᶠ v

    merge-∃-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n
    merge-∃-con af (con-var v) = con-var (merge-∃-var af v)
    merge-∃-con af (v ∧ᵈⁿᶠ c) = merge-∃-var af v ∧ᵈⁿᶠ merge-∃-con af c

    merge-∃-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
    merge-∃-dis af (dis-con c) = dis-con (merge-∃-con af c)
    merge-∃-dis af (c ∨ᵈⁿᶠ d) = merge-∃-con af c ∨ᵈⁿᶠ merge-∃-dis af d
  f'→fᵈⁿᶠ ([ af ]' f') = merge-∀-dis af (f'→fᵈⁿᶠ f')
    where
    merge-∀-var : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-var C n → Formulaᵈⁿᶠ-var C n
    merge-∀-var af v = [ af ]ᵈⁿᶠ v

    merge-∀-con : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-con C n → Formulaᵈⁿᶠ-con C n
    merge-∀-con af (con-var v) = con-var (merge-∀-var af v)
    merge-∀-con af (v ∧ᵈⁿᶠ c) = merge-∀-var af v ∧ᵈⁿᶠ merge-∀-con af c

    merge-∀-dis : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → {n : ℕ} → ActionFormula C → Formulaᵈⁿᶠ-dis C n → Formulaᵈⁿᶠ-dis C n
    merge-∀-dis af (dis-con c) = dis-con (merge-∀-con af c)
    merge-∀-dis af (c ∨ᵈⁿᶠ d) = merge-∀-con af c ∨ᵈⁿᶠ merge-∀-dis af d
  f'→fᵈⁿᶠ (μ' f') = dis-con (con-var (μᵈⁿᶠ f'→fᵈⁿᶠ f'))
  f'→fᵈⁿᶠ (ν' f') = dis-con (con-var (νᵈⁿᶠ f'→fᵈⁿᶠ f'))
  f'→fᵈⁿᶠ (ref'〔 false 〕 _) = dis-con con-var falseᵈⁿᶠ
  f'→fᵈⁿᶠ (ref'〔 true 〕 i) = dis-con (con-var (refᵈⁿᶠ i))

infix 45 ref_
infix 40 ¬_
infixr 35 _∧_
infixr 35 _∨_
infixr 35 _⇒_
infix 30 ⟨_⟩_
infix 30 [_]_
infix 30 μ_．_
infix 30 ν_．_

data Formula (C : Containerˢᵗᵈ ℓ₁ ℓ₂) : Set ℓ₁ where
  true false : Formula C
  ¬_ : Formula C → Formula C
  _∧_ _∨_ _⇒_ : Formula C → Formula C → Formula C
  ⟨_⟩_ [_]_ : ActionFormula C → Formula C → Formula C
  μ_．_ ν_．_ : String → Formula C → Formula C
  ref_ : String → Formula C

infix 25 _⊩_

_⊩_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {α : Set ℓ₃} → Formula C → C ⋆ α → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₃)
f ⊩ x = f→fⁱ f [] ⊩ⁱ x
  where
  f→fⁱ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → Formula C → (xs : List String) → Formulaⁱ C (length xs)
  f→fⁱ true xs = trueⁱ
  f→fⁱ false xs = falseⁱ
  f→fⁱ (¬ f) xs = ¬ⁱ f→fⁱ f xs
  f→fⁱ (f₁ ∧ f₂) xs = f→fⁱ f₁ xs ∧ⁱ f→fⁱ f₂ xs
  f→fⁱ (f₁ ∨ f₂) xs = f→fⁱ f₁ xs ∨ⁱ f→fⁱ f₂ xs
  f→fⁱ (f₁ ⇒ f₂) xs = f→fⁱ f₁ xs ⇒ⁱ f→fⁱ f₂ xs
  f→fⁱ (⟨ af ⟩ f) xs = ⟨ af ⟩ⁱ f→fⁱ f xs
  f→fⁱ ([ af ] f) xs = [ af ]ⁱ f→fⁱ f xs
  f→fⁱ (μ x ． f) xs = μⁱ f→fⁱ f (x ∷ xs)
  f→fⁱ (ν x ． f) xs = νⁱ f→fⁱ f (x ∷ xs)
  f→fⁱ (ref x) xs with findIndexᵇ (_==_ x) xs
  ... | just i = refⁱ i
  ... | nothing = falseⁱ

infix 25 _⊩_!_

_⊩_!_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {I : Set ℓ₃} → {O : I → Set ℓ₄} → Formula C → Program C I O → I → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₄)
f ⊩ x ! i = f ⊩ x i

infix 25 _▸_⊩_!_

_▸_⊩_!_ : {C : Containerˢᵗᵈ ℓ₁ ℓ₂} → ⦃ IsDecEquivalence {A = Shapeˢᵗᵈ C} _≡_ ⦄ → {I : Set ℓ₃} → {O : I → Set ℓ₄} → ℕ → Formula C → RecursiveProgram C I O → I → Set (ℓ₁ ⊔ ℓ₂ ⊔ ℓ₄)
n ▸ f ⊩ x ! i = f ⊩ (recursionHandler x n) i

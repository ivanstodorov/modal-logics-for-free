{-# OPTIONS --overlapping-instances #-}
module ModalLogics.HennessyMilnerLogic.Examples.Authentication where

open import Common.Effect
open import Common.Free
open import Common.Program
open import Data.Bool using (Bool; if_then_else_)
open import Data.Empty using (⊥) renaming (⊥-elim to ⊥-elim₀)
open import Data.Empty.Polymorphic using (⊥-elim)
open import Data.Nat using (ℕ; zero; suc; _≟_)
open import Data.Product using (_,_)
open import Data.Sum using (inj₁; inj₂)
open import Data.Unit using (⊤) renaming (tt to tt₀)
open import Data.Unit.Polymorphic using (tt)
open import Function using (_∘_; const; id)
open import Level using (Level; 0ℓ; lift)
open import ModalLogics.HennessyMilnerLogic.Base
open import Relation.Binary.Definitions using (Decidable)
open import Relation.Binary.PropositionalEquality using (_≡_; _≢_) renaming (refl to refl')
open import Relation.Binary.PropositionalEquality.Properties using (isDecEquivalence)
open import Relation.Binary.Structures using (IsDecEquivalence)
open import Relation.Nullary using (does; proof; yes; no; ofʸ; ofⁿ; _because_)

open Effect
open _:<:_
open IsDecEquivalence ⦃...⦄

private variable
  ℓ₁ ℓ₂ ℓ₃ : Level

data AuthOperations : Set where
  login : ℕ → AuthOperations
  logout : AuthOperations

authEffect : Effect 0ℓ 0ℓ
C authEffect = AuthOperations
R authEffect (login _) = Bool
R authEffect logout = ⊤

instance
  authEffectEqIsDecEq : IsDecEquivalence {A = C authEffect} _≡_
  authEffectEqIsDecEq = isDecEquivalence authEffectEqDec
    where
    authEffectEqDec : Decidable {A = C authEffect} _≡_
    does (authEffectEqDec (login n₁) (login n₂)) with Data.Nat._≟_ n₁ n₂
    ... | no _ = Bool.false
    ... | yes _ = Bool.true
    does (authEffectEqDec (login _) logout) = Bool.false
    does (authEffectEqDec logout (login _)) = Bool.false
    does (authEffectEqDec logout logout) = Bool.true
    proof (authEffectEqDec (login n₁) (login n₂)) with Data.Nat._≟_ n₁ n₂
    ... | no ¬p = ofⁿ λ {refl' → ¬p refl'}
    ... | yes refl' = ofʸ refl'
    proof (authEffectEqDec (login _) logout) = ofⁿ λ ()
    proof (authEffectEqDec logout (login _)) = ofⁿ λ ()
    proof (authEffectEqDec logout logout) = ofʸ refl'

loginC : {ε : Effect ℓ₁ ℓ₂} → ⦃ authEffect :<: ε ⦄ → ℕ → C ε
loginC ⦃ inst ⦄ = (injC inst) ∘ login

loginF : {ε : Effect ℓ₁ ℓ₂} → ⦃ authEffect :<: ε ⦄ → ℕ → Free ε Bool
loginF ⦃ inst ⦄ n = step (loginC n) (pure ∘ projR inst)

logoutC : {ε : Effect ℓ₁ ℓ₂} → ⦃ authEffect :<: ε ⦄ → C ε
logoutC ⦃ inst ⦄ = injC inst logout

logoutF : {ε : Effect ℓ₁ ℓ₂} → ⦃ authEffect :<: ε ⦄ → Free ε ⊤
logoutF ⦃ inst ⦄ = step logoutC (pure ∘ projR inst)

exceptionEffect : Effect 0ℓ 0ℓ
C exceptionEffect = ⊤
R exceptionEffect _ = ⊥

instance
  exceptionEffectEqIsDecEq : IsDecEquivalence {A = C exceptionEffect} _≡_
  exceptionEffectEqIsDecEq = isDecEquivalence exceptionEffectEqDec
    where
    exceptionEffectEqDec : Decidable {A = C exceptionEffect} _≡_
    does (exceptionEffectEqDec tt tt) = Bool.true
    proof (exceptionEffectEqDec tt tt) = ofʸ refl'

exceptionC : {ε : Effect ℓ₁ ℓ₂} → ⦃ exceptionEffect :<: ε ⦄ → C ε
exceptionC ⦃ inst ⦄ = injC inst tt₀

exceptionF : {ε : Effect ℓ₁ ℓ₂} → {α : Set ℓ₃} → ⦃ exceptionEffect :<: ε ⦄ → Free ε α
exceptionF ⦃ inst ⦄ = step exceptionC (⊥-elim₀ ∘ projR inst)

testProgram : program (authEffect :+: exceptionEffect) ℕ (const ⊤)
testProgram n = do
  b ← loginF n
  ( if b
    then logoutF
    else exceptionF )

property₁ : Formula (authEffect :+: exceptionEffect)
property₁ = [ logoutC ] false

test₁ : property₁ ⊢ testProgram ! 0
test₁ = tt

property₂ : Formula (authEffect :+: exceptionEffect)
property₂ = ⟨ loginC 0 ⟩ ⟨ logoutC ⟩ true

test₂ : property₂ ⊢ testProgram ! 0
test₂ = lift Bool.true , tt , tt

property₃ : Formula (authEffect :+: exceptionEffect)
property₃ = ⟨ loginC 0 ⟩ [ loginC 0 ] true

test₃ : property₃ ⊢ testProgram ! 0
test₃ = lift Bool.false , tt

property₄ : Formula (authEffect :+: exceptionEffect)
property₄ = ⟨ loginC 0 ⟩ [ logoutC ] false

test₄ : property₄ ⊢ testProgram ! 0
test₄ = lift Bool.false , tt

property₅ : Formula (authEffect :+: exceptionEffect)
property₅ = [ loginC 0 ] [ exceptionC ] false

test₅ : property₅ ⊢ testProgram ! 0
test₅ (lift Bool.false) = ⊥-elim
test₅ (lift Bool.true) = tt

property₆ : Formula (authEffect :+: exceptionEffect)
property₆ = [ loginC 0 ] [ exceptionC ] true

test₆ : property₆ ⊢ testProgram ! 0
test₆ (lift Bool.false) = ⊥-elim
test₆ (lift Bool.true) = tt

property₇ : ℕ → Formula (authEffect :+: exceptionEffect)
property₇ n = [ loginC n ] false

test₇ : ∀ (n : ℕ) → n ≢ 0 → property₇ n ⊢ testProgram ! 0
test₇ zero h = ⊥-elim₀ (h refl')
test₇ (suc _) h = tt

property₈ : (c : C (authEffect :+: exceptionEffect)) → Formula (authEffect :+: exceptionEffect)
property₈ c = ⟨ loginC 0 ⟩ ([ c ] true) ∧ ([ c ] false)

test₈ : ∀ c → property₈ c ⊢ testProgram ! 0
test₈ (inj₁ _) = lift Bool.false , tt , tt
test₈ (inj₂ _) = lift Bool.false , (const tt) , ⊥-elim
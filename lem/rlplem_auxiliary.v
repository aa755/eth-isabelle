(* Generated by Lem from lem/rlplem.lem. *)

Require Import Arith.
Require Import Bool.
Require Import List.
Require Import String.
Require Import Program.Wf.

Open Scope nat_scope.
Open Scope string_scope.


LemmaBE_rev_def_lemma:((foralln,((list_equal_by classical_boolean_equivalence match ( n) with 
 | 0%nat => []
 | n => if nat_ltb n( 256%nat) then [word8FromNatural n] else
         (word8FromNatural ( Nat.modulo n( 256%nat)) :: (fun (n : nat ) => BE_rev_prim n n) ( Nat.div n( 256%nat)))
end ((fun (n : nat ) => BE_rev_prim n n) n)) : Prop)): Prop) .

